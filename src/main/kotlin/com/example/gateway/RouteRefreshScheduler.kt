package com.example.gateway

import org.slf4j.LoggerFactory
import org.springframework.cloud.gateway.event.RefreshRoutesEvent
import org.springframework.context.ApplicationEventPublisher
import org.springframework.scheduling.annotation.EnableScheduling
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component

@Component
@EnableScheduling
class RouteRefreshScheduler(
    private val eventPublisher: ApplicationEventPublisher,
) {
    private val logger = LoggerFactory.getLogger(RouteRefreshScheduler::class.java)

    @Scheduled(fixedDelayString = "\${gateway.routes.refresh-interval:5000}")
    fun refreshRoutes() {
        logger.info("Triggering route refresh...")
        eventPublisher.publishEvent(RefreshRoutesEvent(this))
    }
}
