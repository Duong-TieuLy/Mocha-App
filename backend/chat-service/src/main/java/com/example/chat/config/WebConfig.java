package com.example.chat.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    /**
     * ✅ Static Resource Handler
     * Serve uploaded images từ /uploads/images/
     * URL: http://localhost:8080/uploads/images/filename.jpg
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:uploads/");
    }

    /**
     * ✅ CORS Configuration
     * Cho phép Flutter mobile app (Android/iOS) gọi API
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                // ✅ Cho phép TẤT CẢ origins (phù hợp cho mobile app)
                .allowedOrigins("*")
                // ✅ Hoặc chỉ định cụ thể:
                // .allowedOrigins(
                //     "http://localhost:3000",           // React web
                //     "http://127.0.0.1:3000",          // React web
                //     "http://10.0.2.2:8080",           // Android Emulator
                //     "http://localhost:8080"           // iOS Simulator
                // )
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH")
                .allowedHeaders("*")
                .exposedHeaders("x-temp-id", "Content-Disposition")
                .maxAge(3600);
        // ✅ Bỏ allowCredentials(true) khi dùng allowedOrigins("*")
    }

    /**
     * ✅ RestTemplate Bean
     * Để FriendController có thể gọi UserService API
     */
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}