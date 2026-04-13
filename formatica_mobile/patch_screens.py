import os
import re

dir_path = r"c:\Users\avspn\mediadoc-studio\formatica_mobile\lib\screens"

files = [
    "compress_video_screen.dart",
    "convert_image_screen.dart",
    "convert_video_screen.dart",
    "extract_audio_screen.dart",
    "greyscale_pdf_screen.dart",
    "images_to_pdf_screen.dart",
    "merge_pdf_screen.dart",
    "split_pdf_screen.dart"
]

def patch_file(file_name):
    path = os.path.join(dir_path, file_name)
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Add _currentTaskId
    if "String? _currentTaskId;" not in content:
        content = re.sub(
            r"(String\?\s+_outputPath;\n|String\?\s+_errorMessage;\n|double\s+_progress\s*=\s*0\.0;\n)",
            r"\1  String? _currentTaskId;\n",
            content,
            count=1
        )
    
    # 2. Add local cancel dialog
    if "_showCancelDialog(" not in content:
        cancel_dialog = """
  void _showCancelDialog(BuildContext context, String taskId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text('Cancel Operation', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text('Are you sure you want to cancel the running operation?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () {
              final provider = Provider.of<TaskProvider>(context, listen: false);
              provider.cancelTask(taskId);
              Navigator.pop(ctx);
              _resetForm();
            },
            child: const Text('Yes', style: TextStyle(color: AppColors.audioRose)),
          ),
        ],
      ),
    );
  }
"""
        # insert before the last closing brace
        content = re.sub(r"}\s*$", cancel_dialog + "\n}", content)

    # 3. Find processing variable (like _isConverting, _isCompressing, etc.)
    # We find it by looking for `setState(() { _isXYZ = true;` or `bool _isXYZ = false;`
    m = re.search(r"bool\s+(_is[A-Za-z]+)\s*=\s*false;", content)
    if m:
        is_running_var = m.group(1)
        
        # 4. Patch Button logic
        button_pattern = re.compile(r"(Widget\s+_[a-zA-Z]+Button\(\)\s*\{)(.*?)(\s+return\s+SizedBox\()", re.DOTALL)
        
        def button_replacer(match):
            prefix = match.group(1)
            middle = match.group(2)
            suffix = match.group(3)
            
            if "if ({} )".format(is_running_var) in middle or "_currentTaskId" in middle:
                return match.group(0) # already patched
                
            injection = f"""
    if ({is_running_var}) {{
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: () {{
            if (_currentTaskId != null) {{
              _showCancelDialog(context, _currentTaskId!);
            }}
          }},
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.audioRose,
            side: const BorderSide(color: AppColors.audioRose),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel Operation', style: AppTextStyles.buttonLabel),
        ),
      );
    }}
"""
            return prefix + middle + injection + suffix
            
        content = button_pattern.sub(button_replacer, content)

    # 5. Connect _currentTaskId assignment
    # find lines like `final taskId = provider.addTask(...)`
    # and add `_currentTaskId = taskId;`
    if "_currentTaskId = taskId;" not in content:
        content = re.sub(
            r"(final\s+taskId\s*=\s*provider\.addTask\([^;]+;\s*)",
            r"\1    _currentTaskId = taskId;\n",
            content
        )

    # 6. Pass onCancelSetup to Service if it uses FFMPEG (VideoService, AudioService)
    if "VideoService" in content or "AudioService" in content:
        if "onCancelSetup:" not in content:
            content = re.sub(
                r"(onProgress:\s*\()",
                r"onCancelSetup: (hook) => provider.setCancelHook(taskId, hook),\n        \1",
                content,
                count=1
            )
            
    # 7. Add early return in catch block
    if "('cancelled'))" not in content:
        content = re.sub(
            r"(\}\s*catch\s*\([^\{]+\)\s*\{)",
            r"\1\n      if (e.toString().contains('cancelled') || error.toString().contains('cancelled')) return;",
            content
        )
        
    with open(path, "w", encoding="utf-8") as f:
         f.write(content)

for f in files:
    try:
        patch_file(f)
        print("Patched:", f)
    except Exception as e:
        print("Failed on", f, e)
