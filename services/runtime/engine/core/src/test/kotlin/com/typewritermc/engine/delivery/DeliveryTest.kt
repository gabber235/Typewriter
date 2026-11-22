package com.typewritermc.engine.delivery

import com.typewritermc.engine.delivery.testing.DeliveryHarness
import com.typewritermc.engine.delivery.testing.TestEventCodec
import com.typewritermc.engine.events.testing.Knock
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.Ring
import com.typewritermc.engine.events.testing.TestSource
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.provided
import com.typewritermc.engine.events.testing.reason
import com.typewritermc.engine.events.testing.testShapes
import com.typewritermc.engine.events.testing.verdict
import com.typewritermc.events.AfterHandler
import com.typewritermc.events.Event
import com.typewritermc.events.EventFailure
import com.typewritermc.events.EventResult
import com.typewritermc.events.EventShape
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.Source
import com.typewritermc.events.VerdictHandler
import com.typewritermc.events.deny
import com.typewritermc.events.pass
import com.typewritermc.identity.Engine
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeout
import skirout.editor.v1.event.DeliverEventRequest
import skirout.editor.v1.event.DeliverEventResponse
import skirout.editor.v1.event.EventDelivery
import skirout.editor.v1.event.EventStatus
import skirout.editor.v1.event.OccurrenceId
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import skirout.editor.v1.event.EventSubject as WireSubject
import skirout.kernel.v1.identity.PrincipalId as WirePrincipalId
import skirout.kernel.v1.identity.Protagonist as WireProtagonist

/** Events crossing between engines of one Realm: the sender asks every holder of the subject, each holder answers. */
val DeliveryTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    test("DELIVER-1: an event at a protagonist held only by another engine runs there once and the sender gets done") {
        DeliveryHarness.run {
            val ran = CopyOnWriteArrayList<Poke>()
            val a = engine("a", shapes())
            val b = engine("b", shapes() + afterPoke { ran += it })
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            a.emitter.send(Poke(alex)) shouldBe EventResult.Done

            ran shouldContainExactly listOf(Poke(alex))
        }
    }

    test("DELIVER-2: a deny on the holder gives the sender denied with the holder's code and message") {
        DeliveryHarness.run {
            val a = engine("a", shapes())
            val b = engine("b", shapes() + provided(verdict(Poke::class) { _, _ -> deny(reason("guarded")) }, VERDICT))
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            a.emitter.send(Poke(alex)) shouldBe EventResult.Denied(reason("guarded"))
        }
    }

    test("DELIVER-3: a handler failing with a reason gives that reason; any other throw gives handler_error") {
        DeliveryHarness.run {
            val a = engine("a", shapes())
            val b =
                engine(
                    "b",
                    shapes() +
                        afterPoke { if (it.strength == 1) throw EventFailure(reason("broken")) else error("unexpected") },
                )
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            a.emitter.send(Poke(alex, strength = 1)) shouldBe EventResult.Failed(reason("broken"))
            a.emitter.send(Poke(alex, strength = 2)).shouldBeInstanceOf<EventResult.Failed>().reason.code shouldBe "handler_error"
        }
    }

    test("DELIVER-4: a holder without a handler gives not_handled; an offline protagonist gives not_handled at once") {
        DeliveryHarness.run {
            val a = engine("a", shapes())
            val b = engine("b", shapes())
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            a.emitter.send(Poke(alex)) shouldBe EventResult.NotHandled
            val started = TimeSource.Monotonic.markNow()
            a.emitter.send(Poke(player())) shouldBe EventResult.NotHandled
            (started.elapsedNow() < 1.seconds) shouldBe true
        }
    }

    test("DELIVER-5: a lost delivery is asked again, runs once, and the sender gets done") {
        DeliveryHarness.run {
            val ran = CopyOnWriteArrayList<Poke>()
            val a = engine("a", shapes()) { it.loseRequests(1) }
            val b = engine("b", shapes() + afterPoke { ran += it })
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            a.emitter.send(Poke(alex)) shouldBe EventResult.Done

            ran shouldContainExactly listOf(Poke(alex))
        }
    }

    test("DELIVER-6: a lost answer is asked again and the handler does not run twice") {
        DeliveryHarness.run {
            val ran = CopyOnWriteArrayList<Poke>()
            val a = engine("a", shapes())
            val b = engine("b", shapes() + afterPoke { ran += it }) { it.loseReplies(1) }
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            a.emitter.send(Poke(alex)) shouldBe EventResult.Done

            ran shouldContainExactly listOf(Poke(alex))
        }
    }

    test("DELIVER-7: a handler that ends after the short wait still gives the sender its final result") {
        DeliveryHarness.run {
            val a = engine("a", shapes())
            val b = engine("b", shapes() + afterPoke { delay(1.seconds) })
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            a.emitter.send(Poke(alex)) shouldBe EventResult.Done
        }
    }

    test("DELIVER-8: a holder that never answers gives no_response within the answer limit") {
        DeliveryHarness.run {
            val a = engine("a", shapes())
            val b = engine("b", shapes()) { it.loseReplies(Int.MAX_VALUE) }
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            val started = TimeSource.Monotonic.markNow()
            a.emitter.send(Poke(alex)).shouldBeInstanceOf<EventResult.Failed>().reason.code shouldBe "no_response"
            (started.elapsedNow() < 8.seconds) shouldBe true
        }
    }

    test("DELIVER-9: a protagonist on two engines runs once on each, and a deny on either wins") {
        DeliveryHarness.run {
            val onA = CopyOnWriteArrayList<Poke>()
            val onB = CopyOnWriteArrayList<Poke>()
            val a = engine("a", shapes() + afterPoke { onA += it })
            val b =
                engine(
                    "b",
                    shapes() + afterPoke { onB += it } +
                        provided(verdict(Poke::class) { poke, _ -> if (poke.strength == 2) deny(reason("guarded")) else pass() }, VERDICT),
                )
            val alex = player()
            a.reporter.connected(alex, SessionId("alex-a"))
            b.reporter.connected(alex, SessionId("alex-b"))
            sees(a, alex, "a", "b")

            a.emitter.send(Poke(alex)) shouldBe EventResult.Done
            a.emitter.send(Poke(alex, strength = 2)) shouldBe EventResult.Denied(reason("guarded"))

            onA shouldContainExactly listOf(Poke(alex), Poke(alex, strength = 2))
            onB shouldContainExactly listOf(Poke(alex))
        }
    }

    test("DELIVER-10: a holder without the event's type fails naming it; a subject that does not match fails too") {
        DeliveryHarness.run {
            val a = engine("a", shapes())
            val b = engine("b", shapes(), codec = TestEventCodec(knows = emptySet()))
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            val failed = a.emitter.send(Poke(alex)).shouldBeInstanceOf<EventResult.Failed>()
            failed.reason.code shouldBe "unknown_type"
            failed.reason.message shouldContain Poke::class.qualifiedName!!
        }
    }

    test("DELIVER-11: a delivery to the engine the protagonist just left reaches the engine that holds it now") {
        DeliveryHarness.run {
            val onC = CopyOnWriteArrayList<Poke>()
            val a = engine("a", shapes())
            val b = engine("b", shapes())
            val c = engine("c", shapes() + afterPoke { onC += it })
            val alex = player()
            b.reporter.connected(alex, SessionId("alex-b"))
            sees(a, alex, "b")
            c.reporter.connected(alex, SessionId("alex-c"))
            b.reporter.disconnected(SessionId("alex-b"))

            a.emitter.send(Poke(alex)) shouldBe EventResult.Done

            onC shouldContainExactly listOf(Poke(alex))
        }
    }

    test("DELIVER-12: a handler's emit and a source event reach every other holder, also after a lost first ask") {
        DeliveryHarness.run {
            val onA = CopyOnWriteArrayList<Poke>()
            val onB = CopyOnWriteArrayList<Poke>()
            val pokes = TestSource(Poke::class)
            // A source opens while a handler of its own engine could run on its events.
            val a = engine("a", shapes() + afterPoke { onA += it } + provided(pokes, listOf(Source::class))) { it.loseRequests(1) }
            val b = engine("b", shapes() + afterPoke { onB += it })
            val alex = player()
            a.reporter.connected(alex, SessionId("alex-a"))
            b.reporter.connected(alex, SessionId("alex-b"))
            sees(a, alex, "a", "b")

            a.events.emit(Poke(alex, strength = 1))
            pokes.fire(Poke(alex, strength = 2))

            eventually(10.seconds) { onB shouldContainExactly listOf(Poke(alex, strength = 1), Poke(alex, strength = 2)) }
            onA shouldContainExactly listOf(Poke(alex, strength = 1), Poke(alex, strength = 2))
        }
    }

    test("DELIVER-13: events at one protagonist run on the holder in the order they were sent, also when the first is lost") {
        DeliveryHarness.run {
            val onB = CopyOnWriteArrayList<Int>()
            val a = engine("a", shapes()) { it.loseRequests(1) }
            val b = engine("b", shapes() + afterPoke { onB += it.strength })
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            (1..5).forEach { a.events.emit(Poke(alex, strength = it)) }

            eventually(10.seconds) { onB shouldContainExactly (1..5).toList() }
        }
    }

    test("DELIVER-14: a session subject reaches only the engine holding that session") {
        DeliveryHarness.run {
            val knocks = CopyOnWriteArrayList<String>()
            fun knocking(engine: String) = shapes() + provided(after(Knock::class) { _, _ -> knocks += engine }, AFTER)
            val a = engine("a", knocking("a"))
            val b = engine("b", knocking("b"))
            val c = engine("c", knocking("c"))
            val alex = player()
            b.reporter.connected(alex, SessionId("alex-b"))
            c.reporter.connected(alex, SessionId("alex-c"))
            sees(a, alex, "b", "c")

            a.emitter.send(Knock(Session(alex, SessionId("alex-c")))) shouldBe EventResult.Done

            knocks shouldContainExactly listOf("c")
        }
    }

    test("DELIVER-8: a holder that restarts mid run gives holder_restarted") {
        DeliveryHarness.run {
            val started = CompletableDeferred<Unit>()
            val a = engine("a", shapes())
            val b =
                engine(
                    "b",
                    shapes() +
                        afterPoke {
                            started.complete(Unit)
                            delay(10.seconds)
                        },
                )
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            coroutineScope {
                val result = async { a.emitter.send(Poke(alex)) }
                started.await()
                // The sender's first ask is answered running after its short wait; only then did the holder take it.
                delay(1.seconds)
                b.close()
                engine("b", shapes()).reporter.connected(alex, SessionId("alex"))

                result.await().shouldBeInstanceOf<EventResult.Failed>().reason.code shouldBe "holder_restarted"
            }
        }
    }

    test("DELIVER-8: a handler outlasting the limit gives timeout, and it still finishes") {
        DeliveryHarness.run {
            val finished = CompletableDeferred<Unit>()
            val a = engine("a", shapes(), timings = DeliveryTimings(limit = 1.seconds))
            val b =
                engine(
                    "b",
                    shapes() +
                        afterPoke {
                            delay(2.seconds)
                            finished.complete(Unit)
                        },
                )
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")

            a.emitter.send(Poke(alex)).shouldBeInstanceOf<EventResult.Failed>().reason.code shouldBe "timeout"
            withTimeout(5.seconds) { finished.await() }
        }
    }

    test("DELIVER-10: an event whose subject is not the one it was sent with fails with subject_mismatch") {
        DeliveryHarness.run {
            val a = engine("a", shapes())
            val b = engine("b", shapes() + afterPoke { error("a mismatched event must not run") })
            val alex = player()
            val sam = player()
            b.reporter.connected(sam, SessionId("sam"))
            sees(a, sam, "b")

            val answer = a.link.ask(EngineId("b"), raw(subject = sam, event = Poke(alex)), 5.seconds)

            answer.finalResult().shouldBeInstanceOf<EventResult.Failed>().reason.code shouldBe "subject_mismatch"
        }
    }

    test("DELIVER-14: an engine subject reaches only that engine") {
        DeliveryHarness.run {
            val rings = CopyOnWriteArrayList<String>()
            fun ringing(engine: String) = shapes() + provided(after(Ring::class) { _, _ -> rings += engine }, AFTER)
            val a = engine("a", ringing("a"))
            engine("b", ringing("b"))
            engine("c", ringing("c"))

            a.emitter.send(Ring(Engine(EngineId("c")))) shouldBe EventResult.Done

            rings shouldContainExactly listOf("c")
        }
    }

    test("a holder forgets a final occurrence after its window, so a later confirmed ask learns it restarted") {
        DeliveryHarness.run {
            val a = engine("a", shapes())
            val b = engine("b", shapes(), timings = DeliveryTimings(kept = 500.milliseconds))
            val alex = player()
            b.reporter.connected(alex, SessionId("alex"))
            sees(a, alex, "b")
            val first = raw(subject = alex, event = Poke(alex))

            a.link.ask(EngineId("b"), first, 5.seconds).finalResult() shouldBe EventResult.NotHandled
            a.link.ask(EngineId("b"), first.confirmedAsk(), 5.seconds).finalResult() shouldBe EventResult.NotHandled
            delay(2.seconds)

            a.link.ask(EngineId("b"), first.confirmedAsk(), 5.seconds).shouldBeInstanceOf<DeliverEventResponse.ForgottenErrorWrapper>()
        }
    }
}

private val AFTER = listOf(AfterHandler::class, HandlerPlan::class)
private val VERDICT = listOf(VerdictHandler::class, HandlerPlan::class)

private fun player() = Protagonist(PrincipalId(PrincipalId.MINECRAFT, UUID.randomUUID().toString()))

private fun shapes() = testShapes.map { provided(it, listOf(EventShape::class)) }

private fun afterPoke(run: suspend (Poke) -> Unit) = listOf(provided(after(Poke::class) { poke, _ -> run(poke) }, AFTER))

/** A first ask of [event] sent with [subject], as a sender builds it, waiting long enough for a final answer. */
private fun raw(
    subject: Protagonist,
    event: Event,
) = DeliverEventRequest(
    delivery =
        EventDelivery(
            occurrence = OccurrenceId(value = UUID.randomUUID().toString()),
            subject = WireSubject.ProtagonistWrapper(WireProtagonist(principal = WirePrincipalId(kind = subject.principal.kind, id = subject.principal.id))),
            event = TestEventCodec().encode(event),
            origin = null,
        ),
    waitMs = 2000,
    confirmed = false,
)

private fun DeliverEventRequest.confirmedAsk() = DeliverEventRequest(delivery = delivery, waitMs = waitMs, confirmed = true)

private fun DeliverEventResponse?.finalResult(): EventResult {
    val status = this.shouldBeInstanceOf<DeliverEventResponse.SuccessWrapper>().value
    return status.shouldBeInstanceOf<EventStatus.FinalWrapper>().value.toResult(TestEventCodec())
}
