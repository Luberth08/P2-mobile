#!/usr/bin/env python3
"""
Script para generar el ícono de la aplicación SmartAssist
Requiere: pip install pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

def create_app_icon(size=1024):
    """Crea el ícono de la aplicación con el estilo SmartAssist - Diseño profesional"""
    
    # Colores del tema
    primary_color = (147, 45, 48)  # #932D30
    secondary_color = (183, 99, 105)  # #B76369
    accent_color = (82, 52, 26)  # #52341A
    background_color = (245, 242, 235)  # #F5F2EB
    white = (255, 255, 255)
    
    # Crear imagen con fondo degradado
    img = Image.new('RGB', (size, size), primary_color)
    draw = ImageDraw.Draw(img)
    
    # Crear degradado radial sutil
    for i in range(size // 2):
        alpha = i / (size // 2)
        color = tuple(int(primary_color[j] * (1 - alpha * 0.15) + secondary_color[j] * alpha * 0.15) for j in range(3))
        draw.ellipse([i, i, size - i, size - i], fill=color)
    
    # Parámetros del diseño
    center_x = size // 2
    center_y = size // 2
    
    # Dibujar un escudo/badge moderno como base
    shield_width = size * 0.65
    shield_height = size * 0.7
    shield_top = center_y - shield_height // 2
    shield_bottom = center_y + shield_height // 2
    shield_left = center_x - shield_width // 2
    shield_right = center_x + shield_width // 2
    
    # Crear forma de escudo con bordes redondeados
    shield_points = []
    num_points = 100
    
    # Parte superior redondeada
    for i in range(num_points // 2):
        angle = math.pi * i / (num_points // 2)
        x = center_x + (shield_width // 2) * math.cos(angle)
        y = shield_top + (shield_width // 4) * math.sin(angle)
        shield_points.append((x, y))
    
    # Lados rectos
    shield_points.append((shield_right, shield_top + shield_width // 4))
    shield_points.append((shield_right, shield_bottom - size * 0.1))
    
    # Punta inferior
    shield_points.append((center_x, shield_bottom))
    
    # Lado izquierdo
    shield_points.append((shield_left, shield_bottom - size * 0.1))
    shield_points.append((shield_left, shield_top + shield_width // 4))
    
    # Dibujar escudo con sombra
    shadow_offset = size * 0.015
    shadow_points = [(x + shadow_offset, y + shadow_offset) for x, y in shield_points]
    draw.polygon(shadow_points, fill=(0, 0, 0, 50))
    
    # Dibujar escudo principal
    draw.polygon(shield_points, fill=background_color, outline=white, width=int(size * 0.008))
    
    # Dibujar ícono de carro moderno y minimalista en el centro
    car_scale = 0.35
    car_y_offset = size * 0.05
    
    # Cuerpo del carro (forma más aerodinámica)
    car_body_width = size * car_scale
    car_body_height = size * car_scale * 0.4
    car_body_left = center_x - car_body_width // 2
    car_body_right = center_x + car_body_width // 2
    car_body_top = center_y - car_body_height // 2 + car_y_offset
    car_body_bottom = center_y + car_body_height // 2 + car_y_offset
    
    # Cabina (más estilizada)
    cabin_width = car_body_width * 0.5
    cabin_height = car_body_height * 0.8
    cabin_left = center_x - cabin_width // 2
    cabin_right = center_x + cabin_width // 2
    cabin_top = car_body_top - cabin_height
    cabin_bottom = car_body_top
    
    # Dibujar cabina con esquinas redondeadas
    cabin_radius = size * 0.03
    draw.rounded_rectangle(
        [cabin_left, cabin_top, cabin_right, cabin_bottom],
        radius=cabin_radius,
        fill=primary_color,
        outline=primary_color,
        width=int(size * 0.01)
    )
    
    # Dibujar cuerpo del carro con esquinas redondeadas
    body_radius = size * 0.025
    draw.rounded_rectangle(
        [car_body_left, car_body_top, car_body_right, car_body_bottom],
        radius=body_radius,
        fill=primary_color,
        outline=primary_color,
        width=int(size * 0.01)
    )
    
    # Ventanas (más modernas)
    window_margin = size * 0.012
    window_radius = size * 0.015
    
    # Ventana izquierda
    draw.rounded_rectangle(
        [cabin_left + window_margin, cabin_top + window_margin,
         center_x - window_margin * 2, cabin_bottom - window_margin],
        radius=window_radius,
        fill=secondary_color
    )
    
    # Ventana derecha
    draw.rounded_rectangle(
        [center_x + window_margin * 2, cabin_top + window_margin,
         cabin_right - window_margin, cabin_bottom - window_margin],
        radius=window_radius,
        fill=secondary_color
    )
    
    # Faros delanteros (detalles modernos)
    headlight_radius = size * 0.02
    headlight_y = car_body_top + car_body_height * 0.3
    
    # Faro izquierdo
    draw.ellipse(
        [car_body_left + size * 0.02 - headlight_radius, headlight_y - headlight_radius,
         car_body_left + size * 0.02 + headlight_radius, headlight_y + headlight_radius],
        fill=background_color
    )
    
    # Faro derecho
    draw.ellipse(
        [car_body_right - size * 0.02 - headlight_radius, headlight_y - headlight_radius,
         car_body_right - size * 0.02 + headlight_radius, headlight_y + headlight_radius],
        fill=background_color
    )
    
    # Ruedas (más detalladas y modernas)
    wheel_radius = size * 0.055
    wheel_y = car_body_bottom + wheel_radius * 0.3
    wheel_left_x = car_body_left + car_body_width * 0.25
    wheel_right_x = car_body_right - car_body_width * 0.25
    
    # Función para dibujar rueda moderna
    def draw_modern_wheel(x, y, radius):
        # Llanta exterior
        draw.ellipse(
            [x - radius, y - radius, x + radius, y + radius],
            fill=accent_color,
            outline=primary_color,
            width=int(size * 0.008)
        )
        # Rin interior
        inner_radius = radius * 0.6
        draw.ellipse(
            [x - inner_radius, y - inner_radius, x + inner_radius, y + inner_radius],
            fill=secondary_color,
            outline=accent_color,
            width=int(size * 0.006)
        )
        # Centro del rin
        center_radius = radius * 0.25
        draw.ellipse(
            [x - center_radius, y - center_radius, x + center_radius, y + center_radius],
            fill=accent_color
        )
    
    # Dibujar ruedas
    draw_modern_wheel(wheel_left_x, wheel_y, wheel_radius)
    draw_modern_wheel(wheel_right_x, wheel_y, wheel_radius)
    
    # Agregar símbolo de herramienta/asistencia (llave inglesa moderna)
    tool_size = size * 0.12
    tool_x = center_x
    tool_y = center_y + shield_height * 0.35
    
    # Círculo de fondo para la herramienta
    tool_bg_radius = tool_size * 0.7
    draw.ellipse(
        [tool_x - tool_bg_radius, tool_y - tool_bg_radius,
         tool_x + tool_bg_radius, tool_y + tool_bg_radius],
        fill=primary_color,
        outline=white,
        width=int(size * 0.008)
    )
    
    # Llave inglesa simplificada y moderna
    wrench_width = tool_size * 0.35
    wrench_height = tool_size * 0.8
    
    # Mango de la llave
    draw.rounded_rectangle(
        [tool_x - wrench_width * 0.15, tool_y - wrench_height * 0.4,
         tool_x + wrench_width * 0.15, tool_y + wrench_height * 0.4],
        radius=size * 0.01,
        fill=background_color
    )
    
    # Cabeza de la llave (hexágono simplificado)
    head_size = wrench_width * 0.8
    head_y = tool_y - wrench_height * 0.35
    
    # Hexágono
    hex_points = []
    for i in range(6):
        angle = math.pi / 3 * i - math.pi / 6
        x = tool_x + head_size * math.cos(angle)
        y = head_y + head_size * 0.7 * math.sin(angle)
        hex_points.append((x, y))
    
    draw.polygon(hex_points, fill=background_color, outline=background_color)
    
    # Agujero interior del hexágono
    inner_hex_points = []
    for i in range(6):
        angle = math.pi / 3 * i - math.pi / 6
        x = tool_x + head_size * 0.4 * math.cos(angle)
        y = head_y + head_size * 0.4 * 0.7 * math.sin(angle)
        inner_hex_points.append((x, y))
    
    draw.polygon(inner_hex_points, fill=primary_color)
    
    # Agregar brillo/highlight sutil en el escudo
    highlight_size = size * 0.15
    highlight_x = center_x - shield_width * 0.25
    highlight_y = shield_top + size * 0.1
    
    for i in range(int(highlight_size)):
        alpha = 1 - (i / highlight_size)
        opacity = int(255 * alpha * 0.15)
        color = tuple(list(white[:3]) + [opacity])
        
    return img

def save_android_icons(base_img):
    """Guarda los íconos para Android en diferentes resoluciones"""
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    android_path = 'android/app/src/main/res'
    
    for folder, size in android_sizes.items():
        folder_path = os.path.join(android_path, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(folder_path, 'ic_launcher.png'))
        print(f"✓ Creado {folder}/ic_launcher.png ({size}x{size})")

def save_ios_icons(base_img):
    """Guarda los íconos para iOS"""
    ios_sizes = [
        (20, 1), (20, 2), (20, 3),
        (29, 1), (29, 2), (29, 3),
        (40, 1), (40, 2), (40, 3),
        (60, 2), (60, 3),
        (76, 1), (76, 2),
        (83.5, 2),
        (1024, 1)
    ]
    
    ios_path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    os.makedirs(ios_path, exist_ok=True)
    
    for base_size, scale in ios_sizes:
        size = int(base_size * scale)
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
        filename = f'Icon-{base_size}@{scale}x.png' if scale > 1 else f'Icon-{base_size}.png'
        resized.save(os.path.join(ios_path, filename))
        print(f"✓ Creado {filename} ({size}x{size})")

def main():
    print("🎨 Generando ícono profesional de SmartAssist...")
    print()
    
    # Crear ícono base en alta resolución
    base_icon = create_app_icon(1024)
    
    # Guardar ícono base
    base_icon.save('app_icon_1024.png')
    print("✓ Creado app_icon_1024.png (1024x1024)")
    print()
    
    # Generar íconos para Android
    print("📱 Generando íconos para Android...")
    save_android_icons(base_icon)
    print()
    
    # Generar íconos para iOS
    print("🍎 Generando íconos para iOS...")
    save_ios_icons(base_icon)
    print()
    
    print("✅ ¡Íconos generados exitosamente!")
    print()
    print("Nota: Para Android, los íconos se han guardado en android/app/src/main/res/")
    print("      Para iOS, los íconos se han guardado en ios/Runner/Assets.xcassets/AppIcon.appiconset/")

if __name__ == '__main__':
    main()
