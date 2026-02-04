#!/usr/bin/env python3
"""
Generate app icons and splash screens for Reframe app.
Uses Pillow to create gradient icons with the app logo.
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

# Colors from AppTheme
PRIMARY_COLOR = (99, 102, 241)  # #6366F1 - Vibrant Indigo
SECONDARY_COLOR = (139, 92, 246)  # #8B5CF6 - Purple
BACKGROUND_DARK = (15, 15, 35)  # #0F0F23
WHITE = (255, 255, 255)

def create_gradient(size, color1, color2, direction='diagonal'):
    """Create a gradient image."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    for y in range(size):
        for x in range(size):
            if direction == 'diagonal':
                # Diagonal gradient
                ratio = (x + y) / (2 * size)
            else:
                # Vertical gradient
                ratio = y / size
            
            r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
            g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
            b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
            draw.point((x, y), fill=(r, g, b, 255))
    
    return img

def draw_rounded_rect(draw, coords, radius, fill):
    """Draw a rounded rectangle."""
    x1, y1, x2, y2 = coords
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
    draw.ellipse([x1, y1, x1 + 2*radius, y1 + 2*radius], fill=fill)
    draw.ellipse([x2 - 2*radius, y1, x2, y1 + 2*radius], fill=fill)
    draw.ellipse([x1, y2 - 2*radius, x1 + 2*radius, y2], fill=fill)
    draw.ellipse([x2 - 2*radius, y2 - 2*radius, x2, y2], fill=fill)

def draw_camera_icon(draw, center_x, center_y, size, color):
    """Draw a simplified video camera icon."""
    # Main camera body (rounded rectangle)
    body_width = size * 0.6
    body_height = size * 0.45
    body_x1 = center_x - body_width / 2
    body_y1 = center_y - body_height / 2
    body_x2 = center_x + body_width / 2
    body_y2 = center_y + body_height / 2
    
    radius = size * 0.08
    draw_rounded_rect(draw, (body_x1, body_y1, body_x2, body_y2), radius, color)
    
    # Lens circle
    lens_radius = size * 0.12
    lens_x = center_x - body_width * 0.15
    lens_y = center_y
    draw.ellipse([
        lens_x - lens_radius, lens_y - lens_radius,
        lens_x + lens_radius, lens_y + lens_radius
    ], fill=color, outline=None)
    
    # Inner lens (darker)
    inner_radius = lens_radius * 0.5
    inner_color = tuple(max(0, c - 40) for c in color[:3]) + (255,) if len(color) == 4 else tuple(max(0, c - 40) for c in color)
    draw.ellipse([
        lens_x - inner_radius, lens_y - inner_radius,
        lens_x + inner_radius, lens_y + inner_radius
    ], fill=inner_color)
    
    # Viewfinder triangle on the right
    triangle_size = size * 0.2
    triangle_x = body_x2
    triangle_points = [
        (triangle_x, center_y - triangle_size * 0.4),
        (triangle_x + triangle_size * 0.6, center_y),
        (triangle_x, center_y + triangle_size * 0.4)
    ]
    draw.polygon(triangle_points, fill=color)
    
    # Record button (red dot)
    dot_radius = size * 0.04
    dot_x = center_x + body_width * 0.25
    dot_y = center_y - body_height * 0.2
    draw.ellipse([
        dot_x - dot_radius, dot_y - dot_radius,
        dot_x + dot_radius, dot_y + dot_radius
    ], fill=(239, 68, 68, 255))  # Red

def create_app_icon(size, with_background=True):
    """Create the main app icon."""
    # Create gradient background
    if with_background:
        img = create_gradient(size, PRIMARY_COLOR, SECONDARY_COLOR, 'diagonal')
    else:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    draw = ImageDraw.Draw(img)
    
    # Draw the camera icon in white
    icon_size = size * 0.5
    draw_camera_icon(draw, size / 2, size / 2, icon_size, WHITE)
    
    return img

def create_adaptive_icon_foreground(size):
    """Create Android adaptive icon foreground (icon only, no background)."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw the camera icon in white, centered for safe zone
    icon_size = size * 0.35  # Smaller to fit in safe zone
    draw_camera_icon(draw, size / 2, size / 2, icon_size, WHITE)
    
    return img

def create_adaptive_icon_background(size):
    """Create Android adaptive icon background (gradient only)."""
    return create_gradient(size, PRIMARY_COLOR, SECONDARY_COLOR, 'diagonal')

def create_splash_screen(width, height, dark_mode=True):
    """Create splash screen."""
    bg_color = BACKGROUND_DARK if dark_mode else WHITE
    img = Image.new('RGBA', (width, height), bg_color + (255,))
    draw = ImageDraw.Draw(img)
    
    # Center point
    center_x = width / 2
    center_y = height / 2 - height * 0.05  # Slightly above center
    
    # Draw gradient icon background
    icon_bg_size = min(width, height) * 0.25
    icon_bg = create_gradient(int(icon_bg_size), PRIMARY_COLOR, SECONDARY_COLOR)
    
    # Add rounded corners to icon background
    mask = Image.new('L', (int(icon_bg_size), int(icon_bg_size)), 0)
    mask_draw = ImageDraw.Draw(mask)
    radius = int(icon_bg_size * 0.22)
    draw_rounded_rect(mask_draw, (0, 0, int(icon_bg_size)-1, int(icon_bg_size)-1), radius, 255)
    
    icon_bg.putalpha(mask)
    
    # Paste icon background
    paste_x = int(center_x - icon_bg_size / 2)
    paste_y = int(center_y - icon_bg_size / 2)
    img.paste(icon_bg, (paste_x, paste_y), icon_bg)
    
    # Draw camera icon on top
    icon_size = icon_bg_size * 0.5
    draw_camera_icon(draw, center_x, center_y, icon_size, WHITE)
    
    return img

def save_ios_icons(base_icon, output_dir):
    """Generate all required iOS icon sizes."""
    ios_sizes = [
        (20, 1), (20, 2), (20, 3),  # Notification
        (29, 1), (29, 2), (29, 3),  # Settings
        (40, 1), (40, 2), (40, 3),  # Spotlight
        (60, 2), (60, 3),           # iPhone App
        (76, 1), (76, 2),           # iPad App
        (83.5, 2),                   # iPad Pro
        (1024, 1),                   # App Store
    ]
    
    for base_size, scale in ios_sizes:
        size = int(base_size * scale)
        icon = base_icon.resize((size, size), Image.Resampling.LANCZOS)
        
        if base_size == int(base_size):
            filename = f"Icon-App-{int(base_size)}x{int(base_size)}@{scale}x.png"
        else:
            filename = f"Icon-App-{base_size}x{base_size}@{scale}x.png"
        
        icon.save(os.path.join(output_dir, filename))
        print(f"Created iOS icon: {filename} ({size}x{size})")

def save_android_icons(base_icon, foreground, background, output_dir):
    """Generate all required Android icon sizes."""
    android_sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
    }
    
    adaptive_sizes = {
        'mdpi': 108,
        'hdpi': 162,
        'xhdpi': 216,
        'xxhdpi': 324,
        'xxxhdpi': 432,
    }
    
    for density, size in android_sizes.items():
        res_dir = os.path.join(output_dir, f'mipmap-{density}')
        os.makedirs(res_dir, exist_ok=True)
        
        # Regular launcher icon
        icon = base_icon.resize((size, size), Image.Resampling.LANCZOS)
        icon.save(os.path.join(res_dir, 'ic_launcher.png'))
        print(f"Created Android icon: mipmap-{density}/ic_launcher.png ({size}x{size})")
    
    # Adaptive icons
    for density, size in adaptive_sizes.items():
        res_dir = os.path.join(output_dir, f'mipmap-{density}')
        os.makedirs(res_dir, exist_ok=True)
        
        # Foreground
        fg = foreground.resize((size, size), Image.Resampling.LANCZOS)
        fg.save(os.path.join(res_dir, 'ic_launcher_foreground.png'))
        
        # Background
        bg = background.resize((size, size), Image.Resampling.LANCZOS)
        bg.save(os.path.join(res_dir, 'ic_launcher_background.png'))
        
        print(f"Created Android adaptive icons: mipmap-{density} ({size}x{size})")

def main():
    # Create directories
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    ios_icon_dir = os.path.join(project_root, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    android_res_dir = os.path.join(project_root, 'android/app/src/main/res')
    assets_dir = os.path.join(project_root, 'assets/images')
    
    os.makedirs(ios_icon_dir, exist_ok=True)
    os.makedirs(android_res_dir, exist_ok=True)
    os.makedirs(assets_dir, exist_ok=True)
    
    # Create base icon at high resolution
    print("Generating app icons...")
    base_icon = create_app_icon(1024)
    
    # Create adaptive icon components
    adaptive_fg = create_adaptive_icon_foreground(1024)
    adaptive_bg = create_adaptive_icon_background(1024)
    
    # Save iOS icons
    print("\n--- iOS Icons ---")
    save_ios_icons(base_icon, ios_icon_dir)
    
    # Save Android icons
    print("\n--- Android Icons ---")
    save_android_icons(base_icon, adaptive_fg, adaptive_bg, android_res_dir)
    
    # Save splash screens
    print("\n--- Splash Screens ---")
    
    # iOS splash images (LaunchImage)
    splash_dir = os.path.join(project_root, 'ios/Runner/Assets.xcassets/LaunchImage.imageset')
    os.makedirs(splash_dir, exist_ok=True)
    
    splash_1x = create_splash_screen(375, 667)  # iPhone 8
    splash_2x = create_splash_screen(750, 1334)  # iPhone 8 @2x
    splash_3x = create_splash_screen(1125, 2436)  # iPhone X/11/12
    
    splash_1x.save(os.path.join(splash_dir, 'LaunchImage.png'))
    splash_2x.save(os.path.join(splash_dir, 'LaunchImage@2x.png'))
    splash_3x.save(os.path.join(splash_dir, 'LaunchImage@3x.png'))
    print("Created iOS splash images")
    
    # Android splash (uses drawable)
    android_drawable_dir = os.path.join(android_res_dir, 'drawable')
    android_drawable_v21_dir = os.path.join(android_res_dir, 'drawable-v21')
    os.makedirs(android_drawable_dir, exist_ok=True)
    os.makedirs(android_drawable_v21_dir, exist_ok=True)
    
    # Save app icon for use in assets
    app_icon = create_app_icon(512)
    app_icon.save(os.path.join(assets_dir, 'app_icon.png'))
    print("Created assets/images/app_icon.png")
    
    # Save logo without background
    logo_only = create_app_icon(512, with_background=False)
    logo_only.save(os.path.join(assets_dir, 'logo.png'))
    print("Created assets/images/logo.png")
    
    # Create onboarding images
    print("\n--- Onboarding Images ---")
    
    # Onboarding 1: Camera/capture theme
    onboarding1 = create_splash_screen(800, 800, dark_mode=True)
    onboarding1.save(os.path.join(assets_dir, 'onboarding_capture.png'))
    print("Created onboarding_capture.png")
    
    # Onboarding 2: AI/magic theme  
    onboarding2 = create_gradient(800, (34, 211, 238), (6, 182, 212))  # Cyan gradient
    draw2 = ImageDraw.Draw(onboarding2)
    # Draw sparkles/stars
    for i in range(20):
        import random
        x = random.randint(100, 700)
        y = random.randint(100, 700)
        size = random.randint(3, 8)
        draw2.ellipse([x-size, y-size, x+size, y+size], fill=WHITE)
    onboarding2.save(os.path.join(assets_dir, 'onboarding_ai.png'))
    print("Created onboarding_ai.png")
    
    # Onboarding 3: Share theme
    onboarding3 = create_gradient(800, (249, 115, 22), (251, 146, 60))  # Orange gradient
    onboarding3.save(os.path.join(assets_dir, 'onboarding_share.png'))
    print("Created onboarding_share.png")
    
    print("\n✅ All icons and images generated successfully!")

if __name__ == '__main__':
    main()
