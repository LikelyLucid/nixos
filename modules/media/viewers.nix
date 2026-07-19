{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      default_for =
        desktop_file: mime_types:
        builtins.listToAttrs (
          map (mime_type: {
            name = mime_type;
            value = desktop_file;
          }) mime_types
        );

      image_defaults = default_for "org.gnome.Loupe.desktop" [
        "image/apng"
        "image/avif"
        "image/bmp"
        "image/gif"
        "image/heic"
        "image/jpeg"
        "image/jxl"
        "image/png"
        "image/qoi"
        "image/svg+xml"
        "image/tiff"
        "image/vnd.microsoft.icon"
        "image/webp"
        "image/x-exr"
        "image/x-tga"
      ];

      video_defaults = default_for "io.github.celluloid_player.Celluloid.desktop" [
        "application/mxf"
        "application/ogg"
        "application/x-flash-video"
        "application/x-matroska"
        "video/3gpp"
        "video/3gpp2"
        "video/mp2t"
        "video/mp4"
        "video/mpeg"
        "video/ogg"
        "video/quicktime"
        "video/webm"
        "video/x-flv"
        "video/x-m4v"
        "video/x-matroska"
        "video/x-msvideo"
        "video/x-theora"
        "x-content/video-dvd"
      ];

      audio_defaults = default_for "io.github.celluloid_player.Celluloid.desktop" [
        "audio/aac"
        "audio/flac"
        "audio/m4a"
        "audio/mp3"
        "audio/mp4"
        "audio/mpeg"
        "audio/ogg"
        "audio/opus"
        "audio/wav"
        "audio/webm"
        "audio/x-flac"
        "audio/x-m4a"
        "audio/x-wav"
        "x-content/audio-cdda"
        "x-content/audio-player"
      ];

      document_defaults = default_for "org.gnome.Papers.desktop" [
        "application/illustrator"
        "application/pdf"
        "application/vnd.comicbook+zip"
        "application/vnd.comicbook-rar"
        "application/x-cb7"
        "application/x-cbr"
        "application/x-cbt"
        "application/x-cbz"
        "image/vnd.djvu"
        "image/vnd.djvu+multipage"
      ];
    in
    {
      home.packages = with pkgs; [
        celluloid
        ffmpegthumbnailer
        glycin-loaders
        loupe
        papers
        webp-pixbuf-loader
      ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = image_defaults // video_defaults // audio_defaults // document_defaults;
      };
    };
}
