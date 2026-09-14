import os
import math

# Define models and their output properties
MODELS = {
    "../models/shaft.obj": {"prefix": "shaft", "steps": 32, "max_angle": math.pi / 2},
    "../models/cog.obj": {"prefix": "cog", "steps": 32, "max_angle": math.pi / 2},
    "../models/crank.obj": {"prefix": "crank", "steps": 32, "max_angle": math.pi / 2},
    "../models/wheel.obj": {"prefix": "wheel", "steps": 32, "max_angle": math.pi / 2},
    "../models/block.obj": {"prefix": "block", "steps": 360, "max_angle": 2 * math.pi}
}
OUTPUT_DIR = "../models"

def rotate_z(x, y, angle):
    rx = x * math.cos(angle) - y * math.sin(angle)
    ry = x * math.sin(angle) + y * math.cos(angle)
    return rx, ry

def bake_all():
    for input_file, config in MODELS.items():
        if not os.path.exists(input_file):
            print(f"Skipping: {input_file} not found.")
            continue

        prefix = config["prefix"]
        steps = config["steps"]
        step_angle = config["max_angle"] / steps

        with open(input_file, "r") as f:
            lines = f.readlines()

        # Find center of this specific model
        v_lines = [l.split() for l in lines if l.startswith("v ")]
        if v_lines:
            xs = [float(v[1]) for v in v_lines]
            ys = [float(v[2]) for v in v_lines]
            center_x = (max(xs) + min(xs)) / 2.0
            center_y = (max(ys) + min(ys)) / 2.0
        else:
            center_x, center_y = 0.0, 0.0

        for step in range(steps):
            angle = step * step_angle
            output_lines = []

            for line in lines:
                tokens = line.split()
                if not tokens:
                    output_lines.append(line)
                    continue

                if tokens[0] == "v":
                    x = float(tokens[1]) - center_x
                    y = float(tokens[2]) - center_y
                    z = float(tokens[3])
                    rx, ry = rotate_z(x, y, angle)
                    output_lines.append(f"v {rx:.6f} {ry:.6f} {z:.6f}\n")
                
                elif tokens[0] == "vn":
                    nx = float(tokens[1])
                    ny = float(tokens[2])
                    nz = float(tokens[3])
                    rnx, rny = rotate_z(nx, ny, angle)
                    output_lines.append(f"vn {rnx:.6f} {rny:.6f} {nz:.6f}\n")
                else:
                    output_lines.append(line)

            out_filename = os.path.join(OUTPUT_DIR, f"{prefix}_{step}.obj")
            with open(out_filename, "w") as out_f:
                out_f.writelines(output_lines)

        print(f"Successfully baked {steps} variants for {prefix}")

if __name__ == "__main__":
    bake_all()