package com.typewritermc.protocol.transport.generated

import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.skir.asPayloadCodec
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import skirout.service.v1.status.EnsureRegistrationLease
import skirout.service.v1.status.QueryServiceBinding
import skirout.service.v1.topology.GetServiceMessagingScope
import skirout.service.v1.topology.RegisterServiceHost
import skirout.service.v1.topology.ReportHostExecution
import skirout.service.v1.topology.WatchHostExecution

data class ServiceRouteScope(val serviceId: String)
private fun String.serviceTemplate() = addressTemplate(
    render = { addressValuesOf("service" to it.serviceId) },
    parse = { ServiceRouteScope(it.require("service")) },
)

private val serviceBindingQueryRequestAddress = "cloud.to.service.{service}.binding.query".serviceTemplate()
private val serviceBindingQueryUpdateAddress = "cloud.from.service.{service}.registration.bound".serviceTemplate()
fun ServiceRouteScope.serviceBindingQuery(policy: ResponsePolicy<skirout.service.v1.status.QueryServiceBindingResponse>, updates: ResponseClassifier<skirout.service.v1.registration.ServiceBoundNotification>) = skirWatchContract(
    method = QueryServiceBinding, updateSerializer = skirout.service.v1.registration.ServiceBoundNotification.serializer,
    name = OperationName.of("registrar.binding"), requestAddress = serviceBindingQueryRequestAddress.subscribedAt(this),
    updateAddress = serviceBindingQueryUpdateAddress, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of("registrar-binding-failed"),
)

private val registrationLeaseEnsureRequestAddress = "cloud.to.service.{service}.registration.ensure".serviceTemplate()
fun ServiceRouteScope.registrationLeaseEnsure(policy: ResponsePolicy<skirout.service.v1.status.EnsureRegistrationLeaseResponse>) = skirUnaryContract(
    method = EnsureRegistrationLease, name = OperationName.of("registrar.registration.ensure"),
    address = registrationLeaseEnsureRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("registrar-registration-ensure-failed"),
)

private val serviceMessagingScopeRequestAddress = "cloud.to.service.{service}.messaging.scope".serviceTemplate()
fun ServiceRouteScope.serviceMessagingScope(policy: ResponsePolicy<skirout.service.v1.topology.GetServiceMessagingScopeResponse>) = skirUnaryContract(
    method = GetServiceMessagingScope, name = OperationName.of("registrar.messaging.scope"),
    address = serviceMessagingScopeRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("registrar-messaging-scope-failed"),
)

private val serviceHostRegisterRequestAddress = "cloud.to.service.{service}.execution.register".serviceTemplate()
fun ServiceRouteScope.serviceHostRegister(policy: ResponsePolicy<skirout.service.v1.topology.RegisterServiceHostResponse>) = skirUnaryContract(
    method = RegisterServiceHost, name = OperationName.of("registrar.execution.register"),
    address = serviceHostRegisterRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("registrar-execution-register-failed"),
)

private val hostExecutionWatchRequestAddress = "cloud.to.service.{service}.execution.watch".serviceTemplate()
private val hostExecutionWatchUpdateAddress = "cloud.from.service.{service}.execution.watch".serviceTemplate()
fun ServiceRouteScope.hostExecutionWatch(policy: ResponsePolicy<skirout.service.v1.topology.WatchHostExecutionResponse>, updates: ResponseClassifier<skirout.service.v1.topology.WatchHostExecutionResponse>) = skirWatchContract(
    method = WatchHostExecution, updateSerializer = skirout.service.v1.topology.WatchHostExecutionResponse.serializer,
    name = OperationName.of("registrar.execution.watch"), requestAddress = hostExecutionWatchRequestAddress.subscribedAt(this),
    updateAddress = hostExecutionWatchUpdateAddress, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of("registrar-execution-watch-failed"),
)

private val hostExecutionReportRequestAddress = "cloud.to.service.{service}.execution.report".serviceTemplate()
fun ServiceRouteScope.hostExecutionReport(policy: ResponsePolicy<skirout.service.v1.topology.ReportHostExecutionResponse>) = skirUnaryContract(
    method = ReportHostExecution, name = OperationName.of("registrar.execution.report"),
    address = hostExecutionReportRequestAddress.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of("registrar-execution-report-failed"),
)

private val serviceHeartbeatAddress = "cloud.to.service.{service}.heartbeat".serviceTemplate()
val ServiceRouteScope.serviceHeartbeat get() = EventContract(
    OperationName.of("registrar.heartbeat"), serviceHeartbeatAddress,
    skirout.service.v1.lifecycle.ServiceHeartbeatNotification.serializer.asPayloadCodec(), ErrorSlug.of("registrar-heartbeat-failed"),
)

private val serviceShutdownAddress = "cloud.to.service.{service}.shutdown".serviceTemplate()
val ServiceRouteScope.serviceShutdown get() = EventContract(
    OperationName.of("registrar.shutdown"), serviceShutdownAddress,
    skirout.service.v1.lifecycle.ServiceShutdownNotification.serializer.asPayloadCodec(), ErrorSlug.of("registrar-shutdown-failed"),
)
