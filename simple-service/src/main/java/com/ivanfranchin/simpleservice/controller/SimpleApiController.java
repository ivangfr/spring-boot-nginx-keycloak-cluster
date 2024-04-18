package com.ivanfranchin.simpleservice.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;

@RestController
public class SimpleApiController {

    @GetMapping("/public")
    public String getPublic() {
        return "Hi World, I am a public endpoint";
    }

    @GetMapping("/secured")
    public String getSecured(Principal principal) {
        return "Hi %s, I am a secured endpoint".formatted(principal.getName());
    }
}