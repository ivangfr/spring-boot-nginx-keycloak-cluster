package com.ivanfranchin.simpleservice.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;

@RestController
public class SimpleServiceController {

    private static final Logger log = LoggerFactory.getLogger(SimpleServiceController.class);

    @GetMapping("/public")
    public String getPublic() {
        log.info("GET /public requested");
        return "Hi World, I am a public endpoint";
    }

    @GetMapping("/secured")
    public String getSecured(Principal principal) {
        log.info("GET /secured requested by {}", principal.getName());
        return "Hi %s, I am a secured endpoint".formatted(principal.getName());
    }
}