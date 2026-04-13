abstract class AppConstants {
  // App info
  static const String appName = 'Formatica';
  static const String appVersion = '2.0.0';

  // Task queue
  static const int maxConcurrentTasks = 3;

  // Backend API configuration (LibreOffice server)
  static const String backendBaseUrl = 'https://darkframeshzn-formatica-backend.hf.space';
  static const String healthEndpoint = '/health/';
  static const String convertEndpoint = '/convert/';
  static const int maxFileSizeBytes = 52428800; // 50MB

  // Supported document formats
  static const List<String> documentInputFormats = [
    'docx',
    'odt',
    'rtf',
    'html',
    'htm',
    'txt',
    'md',
    'epub',
    'pdf',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
  ];

  static const Map<String, List<String>> documentOutputFormats = {
    // All documents converted via LibreOffice backend
    'docx': ['pdf', 'odt', 'html', 'txt', 'rtf', 'epub', 'md'],
    'odt': ['pdf', 'docx', 'html', 'txt', 'rtf', 'epub', 'md'],
    'rtf': ['pdf', 'docx', 'odt', 'html', 'txt', 'md'],
    'html': ['pdf', 'docx', 'odt', 'txt', 'rtf', 'epub', 'md'],
    'htm': ['pdf', 'docx', 'odt', 'txt', 'rtf', 'epub', 'md'],
    'txt': ['pdf', 'docx', 'odt', 'html', 'rtf', 'epub', 'md'],
    'md': ['pdf', 'docx', 'odt', 'html', 'txt', 'rtf', 'epub'],
    'epub': ['pdf', 'docx', 'odt', 'html', 'txt', 'md'],
    
    // Spreadsheets (LibreOffice backend)
    'xlsx': ['pdf'],
    'xls': ['pdf'],
    'csv': ['pdf'],
    
    // Presentations (LibreOffice backend)
    'ppt': ['pdf'],
    'pptx': ['pdf'],
    
    // PDF (LibreOffice backend)
    'pdf': ['docx', 'odt', 'html', 'txt', 'rtf', 'epub'],
  };

  // Video formats
  static const List<String> videoInputFormats = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    'flv',
    'm4v'
  ];
  static const List<String> videoOutputFormats = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    'gif'
  ];

  // Audio formats
  static const List<String> audioOutputFormats = [
    'mp3',
    'aac',
    'wav',
    'flac',
    'ogg'
  ];

  // Image formats
  static const List<String> imageInputFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
    'tiff',
    'tif'
  ];
  static const List<String> imageOutputFormats = [
    'jpg',
    'png',
    'webp',
    'gif',
    'bmp'
  ];
}








