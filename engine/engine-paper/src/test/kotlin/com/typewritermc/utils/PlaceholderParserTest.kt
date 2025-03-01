package com.typewritermc.utils

import com.typewritermc.engine.paper.entry.*
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.arbitrary.double
import io.kotest.property.arbitrary.filter
import io.kotest.property.arbitrary.int
import io.kotest.property.arbitrary.string
import io.kotest.property.checkAll

class PlaceholderParserTest : FunSpec({
    test("Parser should parse with no arguments") {
        val parser = placeholderParser {
            supply {
                "Hey"
            }
        }

        parser.parse(null, emptyList()) shouldBe "Hey"
    }

    test("Parser with no argument should fail when given an argument") {
        val parser = placeholderParser {
            supply {
                "Hey"
            }
        }

        parser.parse(null, listOf("Hello")) shouldBe null
    }

    context("Literals") {
        test("Parser with single literal should parse when given the literal, otherwise it should fail") {
            val parser = placeholderParser {
                literal("hello") {
                    supply {
                        "Hey"
                    }
                }
            }

            parser.parse(null, listOf("hello")) shouldBe "Hey"
            parser.parse(null, listOf("world")) shouldBe null
            parser.parse(null, listOf("hello", "world")) shouldBe null
            parser.parse(null, emptyList()) shouldBe null
        }
        test("Parser with multiple literals should only parse when all literals are supplied") {
            val parser = placeholderParser {
                literal("hello") {
                    supply {
                        "Hey"
                    }
                }
                literal("world") {
                    supply {
                        "World"
                    }
                }
            }

            parser.parse(null, listOf("hello")) shouldBe "Hey"
            parser.parse(null, listOf("world")) shouldBe "World"
            parser.parse(null, listOf("something")) shouldBe null
            parser.parse(null, listOf("hello", "world")) shouldBe null
            parser.parse(null, emptyList()) shouldBe null
        }
        test("Parser with multiple nested literals should only parse the correct literals") {
            val parser = placeholderParser {
                literal("hello") {
                    literal("world") {
                        supply {
                            "Hey"
                        }
                    }
                }
            }

            parser.parse(null, listOf("hello", "world")) shouldBe "Hey"
            parser.parse(null, listOf("hello", "something")) shouldBe null
            parser.parse(null, listOf("something", "world")) shouldBe null
            parser.parse(null, emptyList()) shouldBe null
        }
        test("Parser with multiple executors should only supply the correct executor") {
            val parser = placeholderParser {
                literal("hello") {
                    supply {
                        "Hey"
                    }
                }
                supply {
                    "World"
                }
            }

            parser.parse(null, listOf("hello")) shouldBe "Hey"
            parser.parse(null, listOf("world")) shouldBe null
            parser.parse(null, emptyList()) shouldBe "World"
        }

        test("Parser with overlapping literals will only parse where all arguments match") {
            val parser = placeholderParser {
                literal("hello") {
                    literal("world") {
                        supply {
                            "Hey"
                        }
                    }
                    supply {
                        "World"
                    }
                }
                literal("hello") {
                    literal("sun") {
                        supply {
                            "Sun"
                        }
                    }
                    supply {
                        "Impossible"
                    }
                }
            }

            parser.parse(null, listOf("hello", "world")) shouldBe "Hey"
            parser.parse(null, listOf("hello", "sun")) shouldBe "Sun"
            parser.parse(null, listOf("hello", "something")) shouldBe null
            parser.parse(null, listOf("hello")) shouldBe "World"
            parser.parse(null, emptyList()) shouldBe null
        }
    }

    context("String Argument") {
        test("Parser with string argument should parse when given the argument, otherwise it should fail") {
            val parser = placeholderParser {
                string("name") { string ->
                    supply {
                        "Hey ${string()}"
                    }
                }
            }

            Arb.string().checkAll { string ->
                parser.parse(null, listOf(string)) shouldBe "Hey $string"
            }
            parser.parse(null, emptyList()) shouldBe null
        }

        test("Parser with multiple nested string arguments should only parse when all arguments are supplied") {
            val parser = placeholderParser {
                string("name") { string ->
                    string("action") { action ->
                        supply {
                            "Hey ${string()}, ${action()}"
                        }
                    }
                }
            }

            checkAll<String, String> { string, action ->
                parser.parse(null, listOf(string, action)) shouldBe "Hey $string, $action"
            }
            parser.parse(null, listOf("bob")) shouldBe null
            parser.parse(null, emptyList()) shouldBe null
        }

        test("Parser with literal and string argument should only run the literal") {
            val parser = placeholderParser {
                literal("hello") {
                    supply {
                        "Hey"
                    }
                }

                string("name") { string ->
                    supply {
                        "Hey ${string()}"
                    }
                }
            }

            parser.parse(null, listOf("hello")) shouldBe "Hey"
            Arb.string()
                .filter { it != "hello" }
                .checkAll { string ->
                    parser.parse(null, listOf(string)) shouldBe "Hey $string"
                }
            parser.parse(null, emptyList()) shouldBe null
        }

        test("Parser with where multiple paths are possible should only use the first") {
            val parser = placeholderParser {
                string("name") { string ->
                    supply {
                        "Hey ${string()}"
                    }
                }

                string("name") { string ->
                    supply {
                        "Whats up ${string()}"
                    }
                }
            }

            Arb.string().checkAll { string ->
                parser.parse(null, listOf(string)) shouldBe "Hey $string"
            }
            parser.parse(null, emptyList()) shouldBe null
        }
    }

    context("Int Argument") {
        test("Parser with int argument should parse when given the argument, otherwise it should fail") {
            val parser = placeholderParser {
                int("number") { number ->
                    supply {
                        "Hey ${number()}"
                    }
                }
            }

            Arb.int().checkAll { number ->
                parser.parse(null, listOf(number.toString())) shouldBe "Hey $number"
            }
            parser.parse(null, emptyList()) shouldBe null
        }

        test("Parser with int argument should not parse when something else is given") {
            val parser = placeholderParser {
                int("number") { number ->
                    supply {
                        "Hey ${number()}"
                    }
                }
            }

            Arb.string()
                .filter {
                    try {
                        it.toInt()
                        false
                    } catch (_: NumberFormatException) {
                        true
                    }
                }
                .checkAll { string ->
                    parser.parse(null, listOf(string)) shouldBe null
                }

            Arb.double()
                .filter {
                    it.toInt().toDouble() != it
                }
                .checkAll { number ->
                    parser.parse(null, listOf(number.toString())) shouldBe null
                }
            parser.parse(null, emptyList()) shouldBe null
        }
    }

    context("Enum Argument") {
        test("Parser with enum argument should parse when given the argument, otherwise it should fail") {
            val parser = placeholderParser {
                enum("enum", TestEnum::class) { enum ->
                    supply {
                        "Hey ${enum().name}"
                    }
                }
            }

            parser.parse(null, listOf("TEST")) shouldBe "Hey TEST"
            parser.parse(null, listOf("test")) shouldBe "Hey TEST"
            parser.parse(null, listOf("Test")) shouldBe "Hey TEST"
            parser.parse(null, listOf("test1")) shouldBe null
            parser.parse(null, emptyList()) shouldBe null
        }
    }
})

enum class TestEnum {
    TEST,
}