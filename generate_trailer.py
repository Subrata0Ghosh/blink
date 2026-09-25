import os
import subprocess
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_trailer():
    print("Starting BLINK video trailer generation...")

    width, height = 1920, 1080
    fps = 30
    duration_per_slide = [3.5, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5] # 8 slides = 28.0s
    total_duration = sum(duration_per_slide)
    total_frames = int(total_duration * fps)

    # Base paths
    base_dir = os.path.dirname(os.path.abspath(__file__))
    branding_dir = os.path.join(base_dir, "assets", "images", "branding")
    audio_dir = os.path.join(base_dir, "assets", "audio")

    # Load Background
    bg_path = os.path.join(branding_dir, "play_store_feature_graphic_1024x500.png")
    if os.path.exists(bg_path):
        bg_raw = Image.open(bg_path).convert("RGBA")
        bg_img = bg_raw.resize((width, height), Image.Resampling.LANCZOS)
        # Apply dark cinematic overlay & blur
        bg_img = bg_img.filter(ImageFilter.GaussianBlur(12))
        darkener = Image.new("RGBA", (width, height), (7, 10, 22, 175))
        bg_img = Image.alpha_composite(bg_img, darkener)
    else:
        bg_img = Image.new("RGBA", (width, height), (10, 14, 26, 255))

    # Fonts
    font_title = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 62)
    font_sub = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 30)
    font_tag = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 22)
    font_bullet = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 26)
    font_hero = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 84)

    # Slide Definitions
    slides = [
        {
            "tag": "✦ THE ATMOSPHERIC PUZZLE GAME ✦",
            "title": "BLINK",
            "subtitle": "The World Changes When You Look Away",
            "bullets": ["Observe the celestial cosmos", "Memorize shifting elements", "Spot what transformed"],
            "image": os.path.join(branding_dir, "play_store_icon_512.png"),
            "is_icon": True,
        },
        {
            "tag": "✦ STEP INTO THE REALM ✦",
            "title": "EXPLORE FLOATING ISLANDS",
            "subtitle": "Journey across mystical celestial dimensions",
            "bullets": ["3D Floating Island realms", "Guided by Nova companion", "Unlock challenging levels"],
            "image": os.path.join(branding_dir, "screenshot_1.png"),
            "is_icon": False,
        },
        {
            "tag": "✦ PHASE 1 : OBSERVATION ✦",
            "title": "MEMORIZE THE REALM",
            "subtitle": "Focus on runes, relics, and celestial crystals",
            "bullets": ["Countdown observation timer", "Detailed cosmic artifacts", "Sharpen your memory & acuity"],
            "image": os.path.join(branding_dir, "screenshot_2.png"),
            "is_icon": False,
        },
        {
            "tag": "✦ PHASE 2 : THE SHIFT ✦",
            "title": "BLINK! REALITY SHIFTS",
            "subtitle": "A cosmic shockwave alters the universe",
            "bullets": ["Signature reality shift wave", "Dynamic visual distortion", "Can you spot the difference?"],
            "image": os.path.join(branding_dir, "screenshot_3.png"),
            "is_icon": False,
        },
        {
            "tag": "✦ PHASE 3 : DEDUCTION ✦",
            "title": "SPOT WHAT CHANGED",
            "subtitle": "Tactile options & instant haptic feedback",
            "bullets": ["Neomorphic glowing buttons", "Physics-based interaction", "Streak combos & high scores"],
            "image": os.path.join(branding_dir, "screenshot_4.png"),
            "is_icon": False,
        },
        {
            "tag": "✦ COLLECT & UPGRADE ✦",
            "title": "ANCIENT RELICS VAULT",
            "subtitle": "Unlock legendary cosmic powers",
            "bullets": ["Chrono Eye, Cosmic Prism & Star Compass", "Passive observation perks", "Upgrade with shift gems"],
            "image": os.path.join(branding_dir, "screenshot_6.png"),
            "is_icon": False,
        },
        {
            "tag": "✦ DAILY REWARDS & PROGRESS ✦",
            "title": "DAILY QUESTS & STREAKS",
            "subtitle": "7-day streak rewards and continuous progression",
            "bullets": ["Claim free daily gem chests", "Complete observer objectives", "100% Offline friendly"],
            "image": os.path.join(branding_dir, "screenshot_7.png"),
            "is_icon": False,
        },
        {
            "tag": "✦ AVAILABLE NOW ✦",
            "title": "PLAY BLINK TODAY",
            "subtitle": "Witness reality transform on Google Play",
            "bullets": ["Zero intrusive advertisements", "Offline play anytime, anywhere", "Download now on Google Play!"],
            "image": os.path.join(branding_dir, "screenshot_5.png"),
            "is_icon": False,
        },
    ]

    # Preload and resize screenshot images
    target_h = 860
    target_w = int(target_h * 9 / 16) # ~484px
    loaded_imgs = []
    for s in slides:
        if os.path.exists(s["image"]):
            im = Image.open(s["image"]).convert("RGBA")
            if s.get("is_icon"):
                im = im.resize((500, 500), Image.Resampling.LANCZOS)
            else:
                im = im.resize((target_w, target_h), Image.Resampling.LANCZOS)
            loaded_imgs.append(im)
        else:
            loaded_imgs.append(None)

    # Temporary audio output
    audio_output = os.path.join(base_dir, "trailer_audio.wav")
    final_video = os.path.join(base_dir, "blink_promo_trailer.mp4")

    # Generate synchronized audio mix using ffmpeg
    music_file = os.path.join(audio_dir, "ambient_music.wav").replace("\\", "/")
    sfx_files = [
        os.path.join(audio_dir, "ui_confirm.wav").replace("\\", "/"),
        os.path.join(audio_dir, "ui_click.wav").replace("\\", "/"),
        os.path.join(audio_dir, "countdown.wav").replace("\\", "/"),
        os.path.join(audio_dir, "ui_confirm.wav").replace("\\", "/"),
        os.path.join(audio_dir, "correct.wav").replace("\\", "/"),
        os.path.join(audio_dir, "chest_open.wav").replace("\\", "/"),
        os.path.join(audio_dir, "level_up.wav").replace("\\", "/"),
        os.path.join(audio_dir, "perfect.wav").replace("\\", "/"),
    ]

    audio_cmd = [
        "ffmpeg", "-y",
        "-stream_loop", "3", "-i", music_file,
    ]
    for sfx in sfx_files:
        audio_cmd.extend(["-i", sfx])

    filter_complex = (
        "[0:a]atrim=0:28,afade=t=out:st=26:d=2,volume=0.55[bg];"
        "[1:a]adelay=100|100,volume=1.0[s0];"
        "[2:a]adelay=3600|3600,volume=1.0[s1];"
        "[3:a]adelay=7100|7100,volume=1.0[s2];"
        "[4:a]adelay=10600|10600,volume=1.0[s3];"
        "[5:a]adelay=14100|14100,volume=1.0[s4];"
        "[6:a]adelay=17600|17600,volume=1.0[s5];"
        "[7:a]adelay=21100|21100,volume=1.0[s6];"
        "[8:a]adelay=24600|24600,volume=1.0[s7];"
        "[bg][s0][s1][s2][s3][s4][s5][s6][s7]amix=inputs=9:duration=longest[aout]"
    )
    audio_cmd.extend(["-filter_complex", filter_complex, "-map", "[aout]", "-t", "28", audio_output])

    print("Generating audio mix...")
    subprocess.run(audio_cmd, check=True)

    # Launch ffmpeg video pipe
    video_cmd = [
        "ffmpeg", "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{width}x{height}",
        "-pix_fmt", "rgb24",
        "-r", str(fps),
        "-i", "-", # Pipe stdin
        "-i", audio_output,
        "-c:v", "libx264",
        "-preset", "fast",
        "-crf", "18",
        "-c:a", "aac",
        "-b:a", "192k",
        "-pix_fmt", "yuv420p",
        "-shortest",
        final_video
    ]
    proc = subprocess.Popen(video_cmd, stdin=subprocess.PIPE)

    print("Rendering video frames...")
    cumulative_time = 0
    slide_starts = []
    for d in duration_per_slide:
        slide_starts.append(cumulative_time)
        cumulative_time += d

    for frame_idx in range(total_frames):
        current_time = frame_idx / fps

        # Find current slide
        slide_idx = len(slides) - 1
        for i, start_t in enumerate(slide_starts):
            if current_time < start_t + duration_per_slide[i]:
                slide_idx = i
                break

        slide = slides[slide_idx]
        local_t = current_time - slide_starts[slide_idx]
        slide_dur = duration_per_slide[slide_idx]

        # Fade in transition (0.4s)
        fade_factor = min(1.0, local_t / 0.4)
        # Fade out transition (last 0.2s)
        time_left = slide_dur - local_t
        if time_left < 0.2:
            fade_factor = min(fade_factor, time_left / 0.2)

        # Subtle Ken Burns drift
        drift_y = int(math.sin(local_t / slide_dur * math.pi) * 8)

        # Base Frame
        frame = bg_img.copy()
        draw = ImageDraw.Draw(frame)

        # Decorative cosmic border card on the left
        card_x, card_y, card_w, card_h = 100, 120, 820, 840
        # Draw translucent glass card
        glass_overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        glass_draw = ImageDraw.Draw(glass_overlay)
        glass_draw.rounded_rectangle([card_x, card_y, card_x + card_w, card_y + card_h], radius=28, fill=(16, 24, 45, 180), outline=(0, 229, 255, int(130 * fade_factor)), width=2)
        frame = Image.alpha_composite(frame, glass_overlay)
        draw = ImageDraw.Draw(frame)

        # Text Alpha
        alpha_text = int(255 * fade_factor)

        # Tag
        draw.text((card_x + 50, card_y + 60 + drift_y), slide["tag"], font=font_tag, fill=(0, 229, 255, alpha_text))

        # Title
        if slide.get("is_icon"):
            draw.text((card_x + 50, card_y + 110 + drift_y), slide["title"], font=font_hero, fill=(255, 255, 255, alpha_text))
            title_offset = 220
        else:
            draw.text((card_x + 50, card_y + 110 + drift_y), slide["title"], font=font_title, fill=(255, 255, 255, alpha_text))
            title_offset = 190

        # Subtitle
        draw.text((card_x + 50, card_y + title_offset + drift_y), slide["subtitle"], font=font_sub, fill=(176, 190, 197, alpha_text))

        # Separator line
        draw.line([card_x + 50, card_y + title_offset + 60 + drift_y, card_x + 700, card_y + title_offset + 60 + drift_y], fill=(124, 77, 255, int(150 * fade_factor)), width=2)

        # Bullet Points
        bullet_start_y = card_y + title_offset + 95 + drift_y
        for b_idx, bullet in enumerate(slide["bullets"]):
            by = bullet_start_y + b_idx * 65
            # Draw glowing dot
            draw.ellipse([card_x + 55, by + 6, card_x + 71, by + 22], fill=(0, 229, 255, alpha_text))
            draw.text((card_x + 88, by), bullet, font=font_bullet, fill=(245, 245, 245, alpha_text))

        # Right Side Graphic / Screenshot
        right_img = loaded_imgs[slide_idx]
        if right_img:
            if slide.get("is_icon"):
                # Centered icon with glowing pulse ring
                ix = 1150 + int((650 - right_img.width) / 2)
                iy = 140 + int((800 - right_img.height) / 2) + drift_y
                pulse_r = int(280 + math.sin(local_t * 4) * 15)
                pulse_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
                p_draw = ImageDraw.Draw(pulse_layer)
                p_draw.ellipse([ix + 250 - pulse_r, iy + 250 - pulse_r, ix + 250 + pulse_r, iy + 250 + pulse_r], outline=(0, 229, 255, int(100 * fade_factor)), width=4)
                frame = Image.alpha_composite(frame, pulse_layer)
                frame.paste(right_img, (ix, iy), right_img)
            else:
                # Smartphone frame mockup
                ix = 1180
                iy = 110 + drift_y
                phone_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
                p_draw = ImageDraw.Draw(phone_layer)
                # Outer chassis with neon rim
                p_draw.rounded_rectangle([ix - 16, iy - 16, ix + target_w + 16, iy + target_h + 16], radius=38, fill=(10, 14, 26, 240), outline=(124, 77, 255, int(180 * fade_factor)), width=3)
                frame = Image.alpha_composite(frame, phone_layer)
                # Paste screenshot
                frame.paste(right_img, (ix, iy), right_img)

        # Write RGB bytes directly to ffmpeg pipe
        rgb_frame = frame.convert("RGB")
        proc.stdin.write(rgb_frame.tobytes())

        if frame_idx % 150 == 0 or frame_idx == total_frames - 1:
            print(f"Rendered frame {frame_idx + 1}/{total_frames} ({(frame_idx + 1)/total_frames*100:.1f}%)")

    proc.stdin.close()
    proc.wait()

    # Clean temporary audio
    if os.path.exists(audio_output):
        try:
            os.remove(audio_output)
        except Exception:
            pass

    print(f"Trailer generation complete: {final_video}")

if __name__ == "__main__":
    create_trailer()
