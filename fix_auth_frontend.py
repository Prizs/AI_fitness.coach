import sys

path = 'mobile_app/lib/services/auth_service.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

old_reg_payload = '''          'patologia_o_alergias': profile.pathologyOrAllergies,
          'alergias_alimentarias': profile.foodAllergies,
          'lesiones_actuales': profile.currentInjuries,
          'discapacidad_motora': profile.motorDisability,
          'zonas_a_evitar': profile.areasToAvoid,
        }),'''

new_reg_payload = '''          'patologia_o_alergias': profile.pathologyOrAllergies,
          'alergias_alimentarias': profile.foodAllergies,
          'lesiones_actuales': profile.currentInjuries,
          'discapacidad_motora': profile.motorDisability,
          'zonas_a_evitar': profile.areasToAvoid,
          'role': profile.role,
          'specialty': profile.specialty,
          'experience_years': profile.experienceYears,
          'certifications': profile.certifications,
        }),'''

text = text.replace(old_reg_payload, new_reg_payload)

old_login = '''      pathologyOrAllergies: user['patologia_o_alergias'] as String?,
      foodAllergies: user['alergias_alimentarias'] as String?,
      currentInjuries: user['lesiones_actuales'] as String?,
      motorDisability: user['discapacidad_motora'] as String?,
      areasToAvoid: user['zonas_a_evitar'] as String?,'''

new_login = '''      pathologyOrAllergies: user['patologia_o_alergias'] as String?,
      foodAllergies: user['alergias_alimentarias'] as String?,
      currentInjuries: user['lesiones_actuales'] as String?,
      motorDisability: user['discapacidad_motora'] as String?,
      areasToAvoid: user['zonas_a_evitar'] as String?,
      role: user['role'] as String? ?? 'client',
      specialty: user['specialty'] as String?,
      experienceYears: user['experience_years'] as int?,
      certifications: user['certifications'] as String?,'''

text = text.replace(old_login, new_login)

old_restore = '''      motorDisability: await _storage.read(key: 'motor_disability'),
      areasToAvoid: await _storage.read(key: 'areas_to_avoid'),
    );
    return true;'''

new_restore = '''      motorDisability: await _storage.read(key: 'motor_disability'),
      areasToAvoid: await _storage.read(key: 'areas_to_avoid'),
      role: await _storage.read(key: 'role') ?? 'client',
    );
    return true;'''

text = text.replace(old_restore, new_restore)

old_save = '''      await _storage.write(key: 'areas_to_avoid', value: profile.areasToAvoid);
    }
  }'''

new_save = '''      await _storage.write(key: 'areas_to_avoid', value: profile.areasToAvoid);
      await _storage.write(key: 'role', value: profile.role);
    }
  }'''

text = text.replace(old_save, new_save)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
