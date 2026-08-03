package com.typewritermc.realm.shell

import com.github.ajalt.clikt.core.BaseCliktCommand
import org.jline.reader.Candidate
import org.jline.reader.Completer
import org.jline.reader.LineReader
import org.jline.reader.ParsedLine

class RealmShellCompleter(
    private val rootCommand: BaseCliktCommand<*>,
) : Completer {
    override fun complete(
        reader: LineReader,
        line: ParsedLine,
        candidates: MutableList<Candidate>,
    ) {
        val words = line.words().filter { it.isNotBlank() }
        val currentWord = line.word() ?: ""

        val targetCommand = resolveCommand(words.dropLast(1))

        val subcommandNames = targetCommand.registeredSubcommandNames()
        val optionNames = targetCommand.registeredOptions().flatMap { it.names }

        val allCandidates = subcommandNames + optionNames

        allCandidates
            .filter { it.startsWith(currentWord, ignoreCase = true) }
            .forEach { candidates.add(Candidate(it)) }
    }

    private fun resolveCommand(words: List<String>): BaseCliktCommand<*> {
        var current: BaseCliktCommand<*> = rootCommand
        for (word in words) {
            val subcommand =
                current.registeredSubcommands().find {
                    it.commandName == word
                } ?: break
            current = subcommand
        }
        return current
    }
}
