import os

files_to_fix = [
    'mobile_app/lib/screens/trainer/client_detail_screen.dart',
    'mobile_app/lib/screens/client_trainer_tab.dart',
    'mobile_app/lib/screens/coach_screen.dart'
]

replacement_old = '''                  child: TextField(
                    controller: _chatController,'''
replacement_old_2 = '''                  child: TextField(''' # In case there's no controller variable locally

replacement_new = '''                  child: TextField(
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,'''

for path in files_to_fix:
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            text = f.read()
        
        # Specifically target the TextField with hintText "Escribe un mensaje..." or "Ej: Â¿QuÃ© calentamiento..."
        # It's safer to just replace all TextField instances inside the chat input Row.
        
        # Method: Find 'hintText: 'Escribe un mensaje...'' or similar, then find the 'TextField(' backwards and replace.
        if 'TextField(' in text:
            text = text.replace('''child: TextField(
                  controller: _chatController,''', 
                  '''child: TextField(
                  controller: _chatController,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,''')

            text = text.replace('''child: TextField(
                    style: const TextStyle(color: Colors.white),''', 
                  '''child: TextField(
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: Colors.white),''')

            text = text.replace('''child: TextField(
                  controller: _controller,''', 
                  '''child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,''')
                  
            text = text.replace('''child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),''', 
                  '''child: TextField(
                    controller: _chatController,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: Colors.white),''')

        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
