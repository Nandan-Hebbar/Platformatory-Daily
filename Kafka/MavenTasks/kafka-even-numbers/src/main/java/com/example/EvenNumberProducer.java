package com.example;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.util.Properties;

public class EvenNumberProducer {
    public static void main(String[] args) {
        String topic = "even-numbers";

        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

        KafkaProducer<String, String> producer = new KafkaProducer<>(props);

        for (int i = 2; i <= 1000; i += 2) {
            producer.send(new ProducerRecord<>(topic, Integer.toString(i)));
            System.out.println("Produced: " + i);
        }

        producer.close();
    }
}

