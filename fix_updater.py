# -*- coding: utf-8 -*-
with open('mobile_app/lib/services/app_update_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_catch = '''    } on Exception catch (error) {
      lastError = 'No se pudo consultar la version: \.';
      return null;
    }'''
new_catch = '''    } on Exception catch (error) {
      lastError = 'Servidor inaccesible (\). Ve a Perfil -> Cambiar Servidor y pega el enlace actual.';
      return null;
    }'''

content = content.replace(old_catch, new_catch)

with open('mobile_app/lib/services/app_update_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
