import sys
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

def apply_watermark(input_path: str, output_path: str, text: str = None, logo_path: str = None, font_size: int = 40, opacity: int = 50, color: str = "white", position: str = "C", logo_scale: float = 0.2) -> dict:
    try:
        # Load image
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # Create an overlay for the watermark
        overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
        
        if logo_path and Path(logo_path).exists():
            # Load and resize logo
            logo = Image.open(logo_path).convert("RGBA")
            lw, lh = logo.size
            
            # Calculate target size based on logo_scale (percentage of input image width)
            target_width = int(width * logo_scale)
            target_height = int(lh * (target_width / lw))
            logo = logo.resize((target_width, target_height), Image.Resampling.LANCZOS)
            lw, lh = logo.size

            # Apply opacity to logo
            alpha = int(255 * (opacity / 100))
            logo_data = logo.getdata()
            new_logo_data = []
            for item in logo_data:
                # Apply opacity but keep transparency
                new_logo_data.append((item[0], item[1], item[2], int(item[3] * (alpha / 255))))
            logo.putdata(new_logo_data)

            # Calculate position
            x, y = 0, 0
            offset = 40
            if position == 'TL': x, y = offset, offset
            elif position == 'TC': x, y = (width - lw) // 2, offset
            elif position == 'TR': x, y = width - lw - offset, offset
            elif position == 'ML': x, y = offset, (height - lh) // 2
            elif position == 'C':  x, y = (width - lw) // 2, (height - lh) // 2
            elif position == 'MR': x, y = width - lw - offset, (height - lh) // 2
            elif position == 'BL': x, y = offset, height - lh - offset
            elif position == 'BC': x, y = (width - lw) // 2, height - lh - offset
            elif position == 'BR': x, y = width - lw - offset, height - lh - offset
            else: x, y = (width - lw) // 2, (height - lh) // 2
            
            overlay.paste(logo, (x, y), logo)

        elif text:
            draw = ImageDraw.Draw(overlay)
            # Load font
            try:
                font = ImageFont.truetype("arial.ttf", font_size)
            except:
                font = ImageFont.load_default()
                
            # Get text size
            bbox = draw.textbbox((0, 0), text, font=font)
            tw = bbox[2] - bbox[0]
            th = bbox[3] - bbox[1]
            
            # Calculate position
            x, y = 0, 0
            offset = 40
            if position == 'TL': x, y = offset, offset
            elif position == 'TC': x, y = (width - tw) // 2, offset
            elif position == 'TR': x, y = width - tw - offset, offset
            elif position == 'ML': x, y = offset, (height - th) // 2
            elif position == 'C':  x, y = (width - tw) // 2, (height - th) // 2
            elif position == 'MR': x, y = width - tw - offset, (height - th) // 2
            elif position == 'BL': x, y = offset, height - th - offset
            elif position == 'BC': x, y = (width - tw) // 2, height - th - offset
            elif position == 'BR': x, y = width - tw - offset, height - th - offset
            else: x, y = (width - tw) // 2, (height - th) // 2
            
            # Set color with opacity
            alpha = int(255 * (opacity / 100))
            if color.startswith("#"):
                # Hex to RGB
                hex_color = color.lstrip("#")
                rgb = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
                fill_color = (*rgb, alpha)
            else:
                fill_color = (255, 255, 255, alpha) if color.lower() == "white" else (0, 0, 0, alpha)
            
            # Draw the text
            draw.text((x, y), text, font=font, fill=fill_color)
        
        # Composite and save as PNG (required for opacity)
        out = Image.alpha_composite(img, overlay)
        
        # Ensure output directory exists
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        
        # Save extension-based
        ext = Path(output_path).suffix.lower()
        if ext in [".jpg", ".jpeg"]:
            out.convert("RGB").save(output_path, "JPEG", quality=95)
        else:
            out.save(output_path, "PNG")
        
        return {"success": True, "output_path": output_path, "error_message": ""}
    except Exception as e:
        return {"success": False, "output_path": "", "error_message": str(e)}

if __name__ == "__main__":
    # Internal CLI for debugging if needed
    pass
