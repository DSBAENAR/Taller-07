package com.arep.secureapp.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class GreetingController {

    @GetMapping("/health")
    public ResponseEntity<?> health() {
        return ResponseEntity.ok(Map.of(
            "status", "UP",
            "service", "SecureApp Spring API",
            "timestamp", LocalDateTime.now().toString()
        ));
    }

    @GetMapping("/greeting")
    public ResponseEntity<?> greeting(@RequestParam(defaultValue = "World") String name) {
        return ResponseEntity.ok(Map.of(
            "message", "Hello, " + name + "!",
            "timestamp", LocalDateTime.now().toString()
        ));
    }
}
