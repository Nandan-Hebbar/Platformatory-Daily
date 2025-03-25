package com.avroapp;

import io.confluent.kafka.serializers.KafkaAvroDeserializer;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

public class AvroConsumer {

    public static void main(String[] args) {
        String topic = "avrotopic3";
        String bootstrapServers = "localhost:9092";
        String schemaRegistryUrl = "http://localhost:8081";

        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "avro-consumers-group");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, KafkaAvroDeserializer.class.getName());
        props.put("schema.registry.url", schemaRegistryUrl);
	props.put("auto.offset.reset", "earliest");

        Consumer<String, Object> consumer = new KafkaConsumer<>(props);
        consumer.subscribe(Collections.singletonList(topic));

        System.out.println("Listening for Avro messages on topic: " + topic);

        try {
            while (true) {
                ConsumerRecords<String, Object> records = consumer.poll(Duration.ofMillis(1000));
                records.forEach(record -> {
                    System.out.printf("Key: %s, Value: %s%n", record.key(), record.value());
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            consumer.close();
        }
    }
}


