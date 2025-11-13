package com.example.gateway

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.cloud.gateway.route.RouteDefinition
import org.springframework.cloud.gateway.route.RouteDefinitionLocator
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.client.WebClient
import reactor.core.publisher.Flux
import reactor.core.publisher.Mono

@Component
class HttpRouteDefinitionLocator(
    @Value("\${gateway.routes.url}") private val routesUrl: String,
    private val webClient: WebClient = WebClient.create(),
) : RouteDefinitionLocator {
    private val logger = LoggerFactory.getLogger(HttpRouteDefinitionLocator::class.java)
    private val yamlMapper = ObjectMapper(YAMLFactory()).registerKotlinModule()

    data class RoutesConfig(
        val routes: List<RouteDefinition> = emptyList(),
    )

    override fun getRouteDefinitions(): Flux<RouteDefinition> =
        fetchRoutesFromHttp()
            .flatMapMany { config -> Flux.fromIterable(config.routes) }
            .doOnNext { logger.info("Loaded route: ${it.id}") }
            .onErrorResume { error ->
                logger.error("Failed to load routes from $routesUrl: ${error.message}")
                Flux.empty()
            }

    private fun fetchRoutesFromHttp(): Mono<RoutesConfig> =
        webClient
            .get()
            .uri(routesUrl)
            .retrieve()
            .bodyToMono(String::class.java)
            .map { yamlString ->
                yamlMapper.readValue(yamlString, RoutesConfig::class.java)
            }
}
