package fixture

import com.typewritermc.types.TypewriterReadModels

data class StarModel(val values: List<*>) // error: StarModel.values.argument 0: Star projections are not authorable.

@TypewriterReadModels(StarModel::class)
object FixtureReadModels
