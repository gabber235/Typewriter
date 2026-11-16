package com.typewritermc.playtest.pool

/**
 * The Papers the pool runs, each under a name and in a folder of its own: the shared Paper, and the own
 * Paper of each restart attempt, named after its attempt. Nothing that ends an older Paper, its exit or
 * the removal of its folder, so reaches a newer one, even the Paper of a later attempt of the same
 * submission. [folderOf] sets up a fresh folder for a name; [remove] removes a Paper's folder.
 */
internal class Papers(
    private val folderOf: (String) -> PaperFolder,
    private val remove: (PaperFolder) -> Unit,
) {
    private val byName = linkedMapOf<String, Server>()

    /** Every Paper that runs now. */
    val all: List<Server> get() = byName.values.toList()

    /** The Paper named [name], while it runs. */
    operator fun get(name: String): Server? = byName[name]

    /** [paper] runs from now on; its name must be free. */
    fun add(paper: Server) {
        check(paper.name !in byName) { "a Paper named ${paper.name} already runs" }
        byName[paper.name] = paper
    }

    /** The own Paper of restart attempt [attempt] of [players], under a name and in a folder after the attempt. */
    fun restart(
        attempt: Long,
        players: Set<String>,
    ): Server {
        val folder = folderOf(Game.OWN_PAPER + attempt)
        return Server(folder, OwnPaper(folder.name, players)).also(::add)
    }

    /** [paper]'s process ended for good: it is forgotten, and its folder goes; its log stays in the run's logs. */
    fun gone(paper: Server) {
        byName.remove(paper.name, paper)
        remove(paper.folder)
    }
}
