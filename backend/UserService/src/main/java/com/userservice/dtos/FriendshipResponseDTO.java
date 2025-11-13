package com.userservice.dtos;

import com.userservice.dtos.UserDTO;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FriendshipResponseDTO {
    private Long id;
    private UserDTO sender;
    private UserDTO receiver;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
