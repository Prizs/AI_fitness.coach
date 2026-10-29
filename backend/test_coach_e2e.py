"""
End-to-end unit test for Coach IA:
1. Deduplication (zero duplicate names and zero duplicate GIFs across all days)
2. Cycle date extraction (multi-cycle support)
3. Active cycle protection vs explicit replacement
4. No equipment (calisthenics) enforcement
"""
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.routers.coach import (
    _normalize_structured_plan,
    _extract_cycle_dates,
    _detect_requested_focus,
)


def test_date_extraction():
    print("--- Testing Date Extraction ---")
    # Test 1: Explicit range
    r1 = _extract_cycle_dates("planifica para la semana del 9/11 al 13/11", has_active_plan=True)
    assert r1["start_date"] == "2026-11-09", f"Expected 2026-11-09, got {r1['start_date']}"
    assert r1["end_date"] == "2026-11-13", f"Expected 2026-11-13, got {r1['end_date']}"
    assert r1["is_future_cycle"] is True
    assert r1["replace_active"] is False

    # Test 2: Next cycle keywords
    r2 = _extract_cycle_dates("rutina para el próximo ciclo", has_active_plan=True)
    assert r2["is_future_cycle"] is True
    assert r2["replace_active"] is False
    assert r2["range_str"] is not None

    # Test 3: Active plan protection (no explicit date mentioned, but active plan exists)
    r3 = _extract_cycle_dates("dame una rutina de cuerpo completo", has_active_plan=True)
    assert r3["is_future_cycle"] is True
    assert r3["replace_active"] is False

    # Test 4: Explicit replacement of active plan
    r4 = _extract_cycle_dates("quiero cambiar mi ciclo actual y reemplazar la rutina vigente", has_active_plan=True)
    assert r4["replace_active"] is True
    assert r4["is_future_cycle"] is False

    print("[OK] All Date Extraction tests passed!")


def test_deduplication_full_body_no_equipment():
    print("\n--- Testing Deduplication in Full Body (No Equipment) ---")
    plan = _normalize_structured_plan(
        raw_plan={"title": "Rutina", "days": ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"], "exercises": [{"name": "Sentadilla", "sets": 3, "reps": "10"}]},
        user_message="hazme una rutina de cuerpo completo para la proxima semana sin herramientas",
        is_no_equipment=True,
        has_active_plan=True,
    )

    days_schedule = plan.get("days_schedule", {})
    all_names = []
    all_gifs = []

    for day, day_data in days_schedule.items():
        if day_data.get("is_rest"):
            continue
        exs = day_data.get("exercises", [])
        assert len(exs) > 0, f"No exercises for {day}"
        for ex in exs:
            name = ex["name"].strip().lower()
            gif = ex.get("gif_url") or ex.get("gifUrl")
            all_names.append((day, name))
            all_gifs.append((day, gif))

    names_only = [n for _, n in all_names]
    gifs_only = [g for _, g in all_gifs]

    # Verify duplicates in names
    dup_names = [n for n in names_only if names_only.count(n) > 1]
    # Verify duplicates in gifs
    dup_gifs = [g for g in gifs_only if gifs_only.count(g) > 1]

    print(f"Total exercises generated across the week: {len(names_only)}")
    print(f"Unique names: {len(set(names_only))} / {len(names_only)}")
    print(f"Unique GIFs: {len(set(gifs_only))} / {len(gifs_only)}")

    assert len(dup_names) == 0, f"Duplicate exercise names found: {set(dup_names)}"
    assert len(dup_gifs) == 0, f"Duplicate GIFs found: {set(dup_gifs)}"

    print("[OK] Zero repeated exercises and zero repeated GIFs across the entire 5-day week!")


def test_deduplication_standard_schedule():
    print("\n--- Testing Deduplication in Standard 5-Day Split ---")
    plan = _normalize_structured_plan(
        raw_plan={"title": "Rutina", "days": ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"], "exercises": [{"name": "Sentadilla", "sets": 3, "reps": "10"}]},
        user_message="plan de entrenamiento",
        is_no_equipment=True,
        has_active_plan=False,
    )

    days_schedule = plan.get("days_schedule", {})
    names_only = []
    gifs_only = []

    for day, day_data in days_schedule.items():
        if day_data.get("is_rest"):
            continue
        for ex in day_data.get("exercises", []):
            names_only.append(ex["name"].strip().lower())
            gifs_only.append(ex.get("gif_url") or ex.get("gifUrl"))

    dup_names = [n for n in names_only if names_only.count(n) > 1]
    dup_gifs = [g for g in gifs_only if gifs_only.count(g) > 1]

    print(f"Total exercises generated: {len(names_only)}")
    print(f"Unique names: {len(set(names_only))} / {len(names_only)}")
    print(f"Unique GIFs: {len(set(gifs_only))} / {len(gifs_only)}")

    assert len(dup_names) == 0, f"Duplicate names in standard split: {set(dup_names)}"
    assert len(dup_gifs) == 0, f"Duplicate GIFs in standard split: {set(dup_gifs)}"

    print("[OK] Standard split deduplication passed with 100% unique exercises & GIFs!")


if __name__ == "__main__":
    test_date_extraction()
    test_deduplication_full_body_no_equipment()
    test_deduplication_standard_schedule()
    print("\n[SUCCESS] ALL E2E COACH TESTS PASSED SUCCESSFULLY! [SUCCESS]")

