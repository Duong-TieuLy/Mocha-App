package com.mocha.momentservice.repository;

import com.mocha.momentservice.model.Moment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface MomentRepository extends JpaRepository<Moment, Long> {

    Page<Moment> findByFirebaseUidInOrderByCreatedAtDesc(List<String> firebaseUids, Pageable pageable);

    Page<Moment> findByFirebaseUidOrderByCreatedAtDesc(String firebaseUid, Pageable pageable);
}