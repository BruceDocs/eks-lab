package com.example.orders;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class OrderConsumer {
    private static final Logger log = LoggerFactory.getLogger(OrderConsumer.class);
    private final OrderRepository repo;

    public OrderConsumer(OrderRepository repo) { this.repo = repo; }

    @KafkaListener(topics = OrderController.TOPIC, groupId = "orders-processor")
    public void onOrder(ConsumerRecord<String, String> rec) {
        log.info("Received order event key={} value={}", rec.key(), rec.value());
        repo.findById(Long.valueOf(rec.key())).ifPresent(o -> {
            o.setStatus("PROCESSED");                                 // update MySQL from Kafka event
            repo.save(o);
        });
    }
}
