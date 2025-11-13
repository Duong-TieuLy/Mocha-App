package com.example.media;

import io.minio.GetPresignedObjectUrlArgs;
import io.minio.MinioClient;
import io.minio.http.Method;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/media")
public class MinioController {

    private final MinioClient minioClient = MinioClient.builder()
            .endpoint("http://localhost:9000")
            .credentials("minioadmin","minioadmin")
            .build();

    @GetMapping("/presign")
    public Map<String,String> presign(@RequestParam String objectName, @RequestParam String method) throws Exception {
        Method m = method.equalsIgnoreCase("PUT") ? Method.PUT : Method.GET;
        String url = minioClient.getPresignedObjectUrl(
                GetPresignedObjectUrlArgs.builder()
                        .method(m)
                        .bucket("chat-media")
                        .object(objectName)
                        .expiry(60*60)
                        .build()
        );
        Map<String,String> out = new HashMap<>();
        out.put("url", url);
        out.put("object", objectName);
        return out;
    }
}