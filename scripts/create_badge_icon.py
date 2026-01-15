"""
Script para criar um ícone .ico com badge de notificação vermelho
Usa o ícone existente e adiciona um círculo vermelho no canto superior direito
"""

from PIL import Image, ImageDraw
import os

def create_badge_icon():
    # Caminho para o ícone original
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    assets_dir = os.path.join(project_dir, 'assets', 'icons')
    
    input_icon = os.path.join(assets_dir, 'favicon.ico')
    output_icon = os.path.join(assets_dir, 'favicon-badge.ico')
    
    print(f"📂 Diretório do projeto: {project_dir}")
    print(f"🔍 Lendo ícone original: {input_icon}")
    
    # Abre o ícone original
    try:
        img = Image.open(input_icon)
        
        # Converte para RGBA se necessário
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Cria uma nova imagem com as mesmas dimensões
        width, height = img.size
        new_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        new_img.paste(img, (0, 0))
        
        # Calcula o tamanho e posição do badge (círculo vermelho)
        badge_size = max(width // 3, 8)  # Pelo menos 8px, máximo 1/3 do tamanho
        badge_x = width - badge_size - 2  # 2px de margem
        badge_y = 2  # 2px de margem no topo
        
        # Desenha o badge
        draw = ImageDraw.Draw(new_img)
        
        # Círculo vermelho com borda branca
        # Borda branca externa
        draw.ellipse(
            [badge_x - 1, badge_y - 1, badge_x + badge_size + 1, badge_y + badge_size + 1],
            fill='white',
            outline='white'
        )
        
        # Círculo vermelho interno
        draw.ellipse(
            [badge_x, badge_y, badge_x + badge_size, badge_y + badge_size],
            fill='#FF0000',
            outline='#FF0000'
        )
        
        # Salva o novo ícone
        new_img.save(output_icon, format='ICO')
        
        print(f"✅ Ícone com badge criado com sucesso: {output_icon}")
        print(f"📏 Tamanho: {width}x{height}px")
        print(f"🔴 Badge: {badge_size}px no canto superior direito")
        
    except FileNotFoundError:
        print(f"❌ Erro: Arquivo não encontrado: {input_icon}")
        print("💡 Certifique-se de que o arquivo favicon.ico existe em assets/icons/")
    except Exception as e:
        print(f"❌ Erro ao criar ícone: {e}")

if __name__ == "__main__":
    print("🎨 Criando ícone com badge de notificação...")
    print("=" * 60)
    
    # Verifica se PIL está instalado
    try:
        from PIL import Image, ImageDraw
        create_badge_icon()
    except ImportError:
        print("❌ Pillow não está instalado!")
        print("💡 Instale com: pip install Pillow")
        print("💡 Ou: python -m pip install Pillow")
