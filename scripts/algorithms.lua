local algorithms = {
    addSignals = require("scripts.algorithms.add-signals"),
    addSupports = require("scripts.algorithms.add-supports"),
    getAlignmentPoints = require("scripts.algorithms.alignment-points"),
    buildBlueprint = require("scripts.algorithms.build-blueprint"),
    pathfind = require("scripts.algorithms.pathfind"),
}

require("scripts.profiling").register(algorithms, "Algorithms")

return algorithms
