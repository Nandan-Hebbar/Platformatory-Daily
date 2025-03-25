package com.example;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Properties;

public class JsonProducer {
    public static void main(String[] args) throws IOException {
        String topic = "json-topic";

        // Kafka Producer Properties
        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

        KafkaProducer<String, String> producer = new KafkaProducer<>(props);

        // Read JSON data from file
        String filePath = "src/main/resources/inputfile.json";
        String jsonData = new String(Files.readAllBytes(Paths.get(filePath)));

        // Send JSON data to Kafka
        producer.send(new ProducerRecord<>(topic, "json_key", jsonData));
        System.out.println("JSON data sent to topic: " + topic);

        producer.close();
    }
}

