"""Dynamic Meta targeting spec builder — fluent builder pattern."""

from typing import Any


class TargetingBuilder:
    """Fluent builder for Meta targeting spec dicts."""

    def __init__(self):
        self._spec: dict[str, Any] = {}

    def set_geo_countries(self, countries: list[str]) -> "TargetingBuilder":
        self._spec.setdefault("geo_locations", {})["countries"] = countries
        return self

    def set_geo_radius(
        self,
        latitude: float,
        longitude: float,
        radius_km: int,
        name: str = "",
    ) -> "TargetingBuilder":
        self._spec.setdefault("geo_locations", {}).setdefault(
            "custom_locations", []
        ).append({
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius_km,
            "distance_unit": "kilometer",
            "name": name,
        })
        return self

    def set_geo_cities(self, city_keys: list[dict]) -> "TargetingBuilder":
        """city_keys: [{"key": "12345", "name": "Kuala Lumpur"}]"""
        self._spec.setdefault("geo_locations", {})["cities"] = city_keys
        return self

    def set_geo_regions(self, region_keys: list[dict]) -> "TargetingBuilder":
        """region_keys: [{"key": "1234"}]"""
        self._spec.setdefault("geo_locations", {})["regions"] = region_keys
        return self

    def set_age(self, age_min: int = 18, age_max: int = 65) -> "TargetingBuilder":
        self._spec["age_min"] = age_min
        self._spec["age_max"] = age_max
        return self

    def set_genders(self, genders: list[int]) -> "TargetingBuilder":
        """1=male, 2=female"""
        self._spec["genders"] = genders
        return self

    def add_custom_audience(self, audience_id: str) -> "TargetingBuilder":
        self._spec.setdefault("custom_audiences", []).append({"id": audience_id})
        return self

    def exclude_custom_audience(self, audience_id: str) -> "TargetingBuilder":
        self._spec.setdefault("excluded_custom_audiences", []).append(
            {"id": audience_id}
        )
        return self

    def add_interests(self, interests: list[dict]) -> "TargetingBuilder":
        """interests: [{"id": "123", "name": "Fitness"}]"""
        targeting = self._spec.setdefault("flexible_spec", [{}])
        targeting[0].setdefault("interests", []).extend(interests)
        return self

    def add_behaviors(self, behaviors: list[dict]) -> "TargetingBuilder":
        """behaviors: [{"id": "456", "name": "Online shoppers"}]"""
        targeting = self._spec.setdefault("flexible_spec", [{}])
        targeting[0].setdefault("behaviors", []).extend(behaviors)
        return self

    def set_advantage_plus_placements(self) -> "TargetingBuilder":
        """Use Meta's automatic placement optimization."""
        self._spec["publisher_platforms"] = [
            "facebook", "instagram", "audience_network", "messenger"
        ]
        return self

    def set_manual_placements(
        self,
        platforms: list[str] | None = None,
        positions: dict[str, list[str]] | None = None,
    ) -> "TargetingBuilder":
        self._spec["publisher_platforms"] = platforms or ["facebook", "instagram"]
        if positions:
            for platform, pos_list in positions.items():
                self._spec[f"{platform}_positions"] = pos_list
        return self

    def set_locales(self, locale_ids: list[int]) -> "TargetingBuilder":
        """Set language targeting. e.g., 6=English, 45=Chinese"""
        self._spec["locales"] = locale_ids
        return self

    def build(self) -> dict[str, Any]:
        """Return the complete targeting spec dict."""
        return self._spec.copy()


class TargetingPresets:
    """Pre-built targeting specs for common use cases."""

    @staticmethod
    def broad_prospecting(
        countries: list[str],
        age_min: int = 18,
        age_max: int = 65,
        genders: list[int] | None = None,
    ) -> dict:
        builder = TargetingBuilder()
        builder.set_geo_countries(countries).set_age(age_min, age_max)
        if genders:
            builder.set_genders(genders)
        builder.set_advantage_plus_placements()
        return builder.build()

    @staticmethod
    def lookalike_prospecting(
        countries: list[str],
        source_audience_id: str,
        exclude_audience_id: str | None = None,
    ) -> dict:
        builder = TargetingBuilder()
        builder.set_geo_countries(countries)
        builder.add_custom_audience(source_audience_id)
        if exclude_audience_id:
            builder.exclude_custom_audience(exclude_audience_id)
        builder.set_advantage_plus_placements()
        return builder.build()

    @staticmethod
    def retargeting_warm(
        countries: list[str],
        warm_audience_id: str,
        purchaser_audience_id: str | None = None,
    ) -> dict:
        builder = TargetingBuilder()
        builder.set_geo_countries(countries)
        builder.add_custom_audience(warm_audience_id)
        if purchaser_audience_id:
            builder.exclude_custom_audience(purchaser_audience_id)
        builder.set_advantage_plus_placements()
        return builder.build()

    @staticmethod
    def hyper_local_radius(
        latitude: float,
        longitude: float,
        radius_km: int = 10,
        age_min: int = 18,
        age_max: int = 55,
        genders: list[int] | None = None,
    ) -> dict:
        builder = TargetingBuilder()
        builder.set_geo_radius(latitude, longitude, radius_km)
        builder.set_age(age_min, age_max)
        if genders:
            builder.set_genders(genders)
        builder.set_advantage_plus_placements()
        return builder.build()
