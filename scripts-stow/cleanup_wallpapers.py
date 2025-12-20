import os
import shutil
import subprocess

WALLPAPER_DIR = "/home/dacrab/Pictures/wallpapers/nord-background"
LOW_RES_DIR = os.path.join(WALLPAPER_DIR, "low_res")
MIN_WIDTH = 1920
MIN_HEIGHT = 1080
TOLERANCE = 0.05 # 5% tolerance

def get_dims(filepath):
    try:
        # Get dimensions using identify
        result = subprocess.run(['identify', '-format', '%w %h', filepath], capture_output=True, text=True, check=True)
        output = result.stdout.strip()
        
        if not output:
            return None
            
        # specific fix for some images having multiple frames
        dims = output.split('\n')[0].split()
        if len(dims) < 2:
            return None
            
        return int(dims[0]), int(dims[1])
    except (subprocess.CalledProcessError, ValueError):
        return None

def is_low_res(width, height):
    # Calculate thresholds with tolerance
    # If image is at least (1 - tolerance) of the target, it's acceptable
    # e.g. 1920 * 0.95 = 1824. 1919 is acceptable.
    threshold_w = MIN_WIDTH * (1 - TOLERANCE)
    threshold_h = MIN_HEIGHT * (1 - TOLERANCE)
    
    # It is low res if BOTH or EITHER are significantly smaller?
    # Usually if it's smaller than the screen in either dimension it might look blurry or have bars.
    # But user wants "close enough".
    
    is_width_bad = width < threshold_w
    is_height_bad = height < threshold_h
    
    return is_width_bad or is_height_bad

def main():
    if not os.path.exists(WALLPAPER_DIR):
        print(f"Directory not found: {WALLPAPER_DIR}")
        return

    if not os.path.exists(LOW_RES_DIR):
        os.makedirs(LOW_RES_DIR)

    # 1. Restore "Close Enough" images from LOW_RES_DIR
    print("Checking for redeemable images in low_res...")
    restored_count = 0
    if os.path.exists(LOW_RES_DIR):
        for filename in os.listdir(LOW_RES_DIR):
             filepath = os.path.join(LOW_RES_DIR, filename)
             if not os.path.isfile(filepath): continue
             
             dims = get_dims(filepath)
             if dims:
                 w, h = dims
                 if not is_low_res(w, h):
                     print(f"Restoring {filename} ({w}x{h}) - close enough to {MIN_WIDTH}x{MIN_HEIGHT}")
                     shutil.move(filepath, os.path.join(WALLPAPER_DIR, filename))
                     restored_count += 1
    
    print(f"Restored {restored_count} images.\n")

    # 2. Scan Main Dir again with relaxed rules
    files = [f for f in os.listdir(WALLPAPER_DIR) if os.path.isfile(os.path.join(WALLPAPER_DIR, f))]
    moved_count = 0
    
    print(f"Scanning {len(files)} files in {WALLPAPER_DIR}...")
    
    for filename in files:
        filepath = os.path.join(WALLPAPER_DIR, filename)
        
        if not filename.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.webp')):
            continue

        dims = get_dims(filepath)
        if not dims:
            continue
            
        width, height = dims
        
        if is_low_res(width, height):
            print(f"Moving {filename} ({width}x{height}) to low_res")
            shutil.move(filepath, os.path.join(LOW_RES_DIR, filename))
            moved_count += 1

    print(f"\nCleanup Complete.")
    print(f"Moved {moved_count} low-resolution images to {LOW_RES_DIR}")

if __name__ == "__main__":
    main()
