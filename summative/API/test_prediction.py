from pathlib import Path

import pytest

from summative.API.prediction import build_feature_frame, predict_wait_time


@pytest.fixture
def sample_payload():
    return {
        'Region': 'North',
        'Day of Week': 'Monday',
        'Season': 'Spring',
        'Time of Day': 'Morning',
        'Urgency Level': 'Low',
        'Patient Outcome': 'Stable',
        'Nurse-to-Patient Ratio': 2.4,
        'Specialist Availability': 1,
        'Facility Size (Beds)': 300,
        'Time to Registration (min)': 10,
        'Time to Triage (min)': 5,
        'Time to Medical Professional (min)': 20,
        'Patient Satisfaction': 4,
    }


def test_build_feature_frame_contains_expected_columns(sample_payload):
    frame = build_feature_frame(sample_payload)
    assert list(frame.columns) == [
        'Region',
        'Day of Week',
        'Season',
        'Time of Day',
        'Urgency Level',
        'Patient Outcome',
        'Nurse-to-Patient Ratio',
        'Specialist Availability',
        'Facility Size (Beds)',
        'Time to Registration (min)',
        'Time to Triage (min)',
        'Time to Medical Professional (min)',
        'Patient Satisfaction',
    ]


def test_predict_wait_time_returns_float(sample_payload):
    prediction = predict_wait_time(sample_payload)
    assert isinstance(prediction, float)
    assert prediction > 0
