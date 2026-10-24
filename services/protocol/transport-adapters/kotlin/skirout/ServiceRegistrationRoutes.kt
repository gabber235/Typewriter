package com.typewritermc.protocol.transport.generated

import com.typewritermc.protocol.transport.ServiceRouteScope
import com.typewritermc.protocol.transport.serviceTemplate
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.skir.skirEventContract
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.communicator.skir.skirWatchContract
import skirout.service.v1.status.EnsureRegistrationLease
import skirout.service.v1.status.QueryServiceBinding
import skirout.service.v1.topology.GetServiceMessagingScope
import skirout.service.v1.topology.RegisterServiceHost
import skirout.service.v1.topology.ReportHostExecution
import skirout.service.v1.topology.WatchHostExecution

private val queryServiceBindingResponsePolicy = ResponsePolicy<skirout.service.v1.status.QueryServiceBindingResponse>(
    skirout.service.v1.status.QueryServiceBindingResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.status.QueryServiceBindingResponse.Kind.BINDING_WRAPPER -> ResponseClassification.success("binding")
        skirout.service.v1.status.QueryServiceBindingResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> ResponseClassification.domainError("service-not-found-error")
        skirout.service.v1.status.QueryServiceBindingResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val ensureRegistrationLeaseResponsePolicy = ResponsePolicy<skirout.service.v1.status.EnsureRegistrationLeaseResponse>(
    skirout.service.v1.status.EnsureRegistrationLeaseResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.status.EnsureRegistrationLeaseResponse.Kind.ISSUED_WRAPPER -> ResponseClassification.success("issued")
        skirout.service.v1.status.EnsureRegistrationLeaseResponse.Kind.ALREADY_BOUND_WRAPPER -> ResponseClassification.success("already-bound")
        skirout.service.v1.status.EnsureRegistrationLeaseResponse.Kind.SERVICE_NOT_FOUND_ERROR_WRAPPER -> ResponseClassification.domainError("service-not-found-error")
        skirout.service.v1.status.EnsureRegistrationLeaseResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val getServiceMessagingScopeResponsePolicy = ResponsePolicy<skirout.service.v1.topology.GetServiceMessagingScopeResponse>(
    skirout.service.v1.topology.GetServiceMessagingScopeResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.topology.GetServiceMessagingScopeResponse.Kind.FOUND_WRAPPER -> ResponseClassification.success("found")
        skirout.service.v1.topology.GetServiceMessagingScopeResponse.Kind.NOT_FOUND_ERROR_WRAPPER -> ResponseClassification.domainError("not-found-error")
        skirout.service.v1.topology.GetServiceMessagingScopeResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val registerServiceHostResponsePolicy = ResponsePolicy<skirout.service.v1.topology.RegisterServiceHostResponse>(
    skirout.service.v1.topology.RegisterServiceHostResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.topology.RegisterServiceHostResponse.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.service.v1.topology.RegisterServiceHostResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val watchHostExecutionResponsePolicy = ResponsePolicy<skirout.service.v1.topology.WatchHostExecutionResponse>(
    skirout.service.v1.topology.WatchHostExecutionResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.topology.WatchHostExecutionResponse.Kind.DESIRED_WRAPPER -> ResponseClassification.success("desired")
        skirout.service.v1.topology.WatchHostExecutionResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val reportHostExecutionResponsePolicy = ResponsePolicy<skirout.service.v1.topology.ReportHostExecutionResponse>(
    skirout.service.v1.topology.ReportHostExecutionResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.service.v1.topology.ReportHostExecutionResponse.Kind.SUCCESS_WRAPPER -> ResponseClassification.success("success")
        skirout.service.v1.topology.ReportHostExecutionResponse.Kind.STALE_REVISION_ERROR_WRAPPER -> ResponseClassification.domainError("stale-revision-error")
        skirout.service.v1.topology.ReportHostExecutionResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}

private val serviceBindingQueryRequestAddress = "cloud.to.service.{service}.binding.query".serviceTemplate()
private val serviceBindingQueryUpdateAddress = "cloud.from.service.{service}.registration.bound".serviceTemplate()
val ServiceRouteScope.serviceBindingQuery get() = skirWatchContract(
    method = QueryServiceBinding, updateSerializer = skirout.service.v1.registration.ServiceBoundNotification.serializer,
    name = OperationName.of("registrar.binding"), requestAddress = serviceBindingQueryRequestAddress.subscribedAt(this),
    updateAddress = serviceBindingQueryUpdateAddress, initialPolicy = queryServiceBindingResponsePolicy,
    limits = TRANSPORT_LIMITS.copy(replyCredit = true),
)

private val registrationLeaseEnsureRequestAddress = "cloud.to.service.{service}.registration.ensure".serviceTemplate()
val ServiceRouteScope.registrationLeaseEnsure get() = skirUnaryContract(
    method = EnsureRegistrationLease, name = OperationName.of("registrar.registration.ensure"),
    address = registrationLeaseEnsureRequestAddress.subscribedAt(this), responsePolicy = ensureRegistrationLeaseResponsePolicy,
    limits = TRANSPORT_LIMITS.copy(replyCredit = true),
)

private val serviceMessagingScopeRequestAddress = "cloud.to.service.{service}.messaging.scope".serviceTemplate()
val ServiceRouteScope.serviceMessagingScope get() = skirUnaryContract(
    method = GetServiceMessagingScope, name = OperationName.of("registrar.messaging.scope"),
    address = serviceMessagingScopeRequestAddress.subscribedAt(this), responsePolicy = getServiceMessagingScopeResponsePolicy,
    limits = TRANSPORT_LIMITS.copy(replyCredit = true),
)

private val serviceHostRegisterRequestAddress = "cloud.to.service.{service}.execution.register".serviceTemplate()
val ServiceRouteScope.serviceHostRegister get() = skirUnaryContract(
    method = RegisterServiceHost, name = OperationName.of("registrar.execution.register"),
    address = serviceHostRegisterRequestAddress.subscribedAt(this), responsePolicy = registerServiceHostResponsePolicy,
    limits = TRANSPORT_LIMITS.copy(replyCredit = true),
)

private val hostExecutionWatchRequestAddress = "cloud.to.service.{service}.execution.watch".serviceTemplate()
private val hostExecutionWatchUpdateAddress = "cloud.from.service.{service}.execution.watch".serviceTemplate()
val ServiceRouteScope.hostExecutionWatch get() = skirWatchContract(
    method = WatchHostExecution, updateSerializer = skirout.service.v1.topology.WatchHostExecutionResponse.serializer,
    name = OperationName.of("registrar.execution.watch"), requestAddress = hostExecutionWatchRequestAddress.subscribedAt(this),
    updateAddress = hostExecutionWatchUpdateAddress, initialPolicy = watchHostExecutionResponsePolicy,
    limits = TRANSPORT_LIMITS.copy(replyCredit = true),
)

private val hostExecutionReportRequestAddress = "cloud.to.service.{service}.execution.report".serviceTemplate()
val ServiceRouteScope.hostExecutionReport get() = skirUnaryContract(
    method = ReportHostExecution, name = OperationName.of("registrar.execution.report"),
    address = hostExecutionReportRequestAddress.subscribedAt(this), responsePolicy = reportHostExecutionResponsePolicy,
    limits = TRANSPORT_LIMITS.copy(replyCredit = true),
)

private val serviceHeartbeatAddress = "cloud.to.service.{service}.heartbeat".serviceTemplate()
val ServiceRouteScope.serviceHeartbeat get() = skirEventContract(
    serializer = skirout.service.v1.lifecycle.ServiceHeartbeatNotification.serializer, name = OperationName.of("registrar.heartbeat"), address = serviceHeartbeatAddress,
)

private val serviceShutdownAddress = "cloud.to.service.{service}.shutdown".serviceTemplate()
val ServiceRouteScope.serviceShutdown get() = skirEventContract(
    serializer = skirout.service.v1.lifecycle.ServiceShutdownNotification.serializer, name = OperationName.of("registrar.shutdown"), address = serviceShutdownAddress,
)
