package com.example.orders;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
public class OrderController {
    static final String TOPIC = "orders";
    private final OrderRepository repo;
    private final KafkaTemplate<String, String> kafka;
    private final ObjectMapper mapper;

    public OrderController(OrderRepository repo, KafkaTemplate<String, String> kafka, ObjectMapper mapper) {
        this.repo = repo; this.kafka = kafka; this.mapper = mapper;
    }

    @PostMapping
    public Order create(@RequestBody Order in) throws JsonProcessingException {
        in.setId(null); in.setStatus("NEW");
        Order saved = repo.save(in);                                  // 1) MySQL
        kafka.send(TOPIC, String.valueOf(saved.getId()),              // 2) Kafka
                   mapper.writeValueAsString(saved));
        return saved;
    }

    @GetMapping
    public List<Order> list() { return repo.findAll(); }

    @GetMapping("/{id}")
    public ResponseEntity<Order> get(@PathVariable Long id) {
        return repo.findById(id).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }
}
