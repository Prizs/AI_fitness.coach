import requests

try:
    print("Sending request to backend...")
    resp = requests.post(
        "https://ai-fitness-coach-wlg3.onrender.com/api/plans/weekly",
        json={
          'goal': 'mejorar condicion fisica',
          'level': 'principiante',
          'age': 25,
          'weight': 70,
          'food_allergies': 'none',
          'current_injuries': 'none',
          'areas_to_avoid': 'none',
        },
        timeout=120
    )
    print("STATUS:", resp.status_code)
    print("BODY:", resp.text[:500])
except Exception as e:
    print("ERROR:", e)
