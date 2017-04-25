#!/usr/bin/python3

from datetime import datetime
import os
import json
import time
import twitter

from kafka import KafkaProducer


def safe_getenv(key):
    val = os.getenv(key)
    if val is None:
        raise Exception("Missing required environment variable: %s" % key)
    return val

KAFKA_HOST = os.getenv("ADVERTISED_HOST", "127.0.0.1")
KAFKA_PORT = os.getenv("ADVERTISED_PORT", "9092")

KAFKA_JSON_TOPIC = "tweets-json"
KAFKA_TSV_TOPIC = "tweets-tsv"

TWITTER_CONSUMER_KEY = safe_getenv("TWITTER_CONSUMER_KEY")
TWITTER_CONSUMER_SECRET = safe_getenv("TWITTER_CONSUMER_SECRET")
TWITTER_ACCESS_TOKEN = safe_getenv("TWITTER_ACCESS_TOKEN")
TWITTER_ACCESS_SECRET = safe_getenv("TWITTER_ACCESS_SECRET")

KEYWORDS_TO_TRACK = ["hawks", "celtics", "nets", "hornets", "bulls", "cavaliers", "mavericks", "nuggets", "pistons", "warriors", "rockets", "pacers", "clippers", "lakers", "grizzlies", "heat", "bucks", "timberwolves", "pelicans", "knicks", "thunder", "magic", "sixers", "suns", "blazers", "kings", "spurs", "raptors", "jazz", "wizards"]
DATETIME_FORMAT = "%a %b %d %H:%M:%S %z %Y"


class KafkaProducerException(Exception):
    pass


def send(producer, topic, bytes):
    try:
        producer.send(topic, bytes)
    except Exception as e:
        print("Failed to send to topic %s: %s" % (topic, bytes))
        raise KafkaProducerException(e)


# Send a tweet to Kafka as a small JSON message.
def send_json(producer, tweet_dict):

    # json.dumps() will return a string with literal backslashes; i.e. a
    # newline in a text field will be the two-character literal \n, and a
    # Unicode code point will be a six-character literal like \u00e9. (Note
    # that json_str itself is still a Python3 Unicode string.)
    json_str = json.dumps(tweet_dict)

    # We need to double-escape everything, because MemSQL will double-parse
    # this string if we try to insert it into a JSON column.
    escaped_json_str = json_str.replace("\\", "\\\\")

    # Send a TSV record with two fields: the tweet's unique ID, and the whole
    # JSON blob. The ID will probably be a primary key column in the eventual
    # destination MemSQL table.
    id_str = str(tweet_dict["id"])
    out = "\t".join([id_str, escaped_json_str])

    # We don't have any special characters in 'out' after the
    # transformations above, so we can write this Unicode string as
    # no-surprises ASCII.
    send(producer, KAFKA_JSON_TOPIC, out.encode("ascii"))


# Send a tweet to Kafka as a TSV record.
def send_tsv(producer, tweet_dict):

    # Make sure that newlines and tabs are escaped in the tweet text and
    # usernames.
    text = tweet_dict["text"].encode("unicode_escape").decode("ascii")
    username = tweet_dict["username"].encode("unicode_escape").decode("ascii")

    out = "\t".join([
        str(tweet_dict["id"]),
        username,
        str(tweet_dict["created_at"]),
        str(tweet_dict["retweet_count"]),
        str(tweet_dict["favorite_count"]),
        text
    ])
    send(producer, KAFKA_TSV_TOPIC, out.encode("ascii"))


def run():
    api = twitter.Api(TWITTER_CONSUMER_KEY,
                      TWITTER_CONSUMER_SECRET,
                      TWITTER_ACCESS_TOKEN,
                      TWITTER_ACCESS_SECRET)

    kafka_broker = "%s:%s" % (KAFKA_HOST, KAFKA_PORT)

    try:
        producer = KafkaProducer(bootstrap_servers=[kafka_broker])
    except Exception as e:
        print("Failed to connect to Kafka broker:", kafka_broker)
        raise KafkaProducerException(e)

    print("Connected to Kafka broker: %s" % kafka_broker)
    print("Using Kafka topics: %s" % [KAFKA_JSON_TOPIC, KAFKA_TSV_TOPIC])

    # GetStreamFilter is a generator that returns dictionaries. Each dict is a
    # Twitter record that has already been decoded by a JSON.loads() call.
    for line in api.GetStreamFilter(track=KEYWORDS_TO_TRACK):

        # This stream will contain control messages that aren't tweets. See
        # https://dev.twitter.com/streaming/overview/messages-types. This will
        # hopefully filter them out.
        if line is None or "retweet_count" not in line:
            continue
        else:
            tweet = line

        # Strip down the tweet to the essentials, to reduce the outbound network
        # usage of Public Kafka.
        keys_to_keep = [
            "favorite_count", "id", "retweet_count", "text"
        ]
        small_tweet = {k: tweet[k] for k in keys_to_keep}
        small_tweet["username"] = tweet["user"]["screen_name"]

        # Include the tweet datetime as a Unix timestamp.
        dt = datetime.strptime(tweet["created_at"], DATETIME_FORMAT)
        small_tweet["created_at"] = int(dt.timestamp())

        # Send these records to two Kafka topics.
        send_json(producer, small_tweet)
        send_tsv(producer, small_tweet)


if __name__ == '__main__':
    while True:
        try:
            run()
        except KafkaProducerException as e:
            print("Kafka producer exception:", e)

            print("Reconnecting in 5 seconds")
            time.sleep(5)
