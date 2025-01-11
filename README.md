
# ByteSnake 🐍

## 🎮 Overview
This project is a functional **Snake game** implemented in **RISC-V Assembly**. It demonstrates efficient game logic, real-time responsiveness, and system-level programming techniques. The game uses:
- **Memory-mapped I/O** for direct keyboard and display control.
- **Timer interrupts** for precise and responsive gameplay.
- **Linear Congruential Generator (LCG)** for randomized apple placement.


## ✨ Features
- Real-time **snake movement** with smooth gameplay.
- **Collision detection** to handle game-over conditions.
- Randomized apple generation for engaging gameplay.
- Efficient use of **assembly programming** techniques and hardware-level operations.


## 🛠️ Technical Details
- **Platform:** RISC-V architecture.
- **Key Concepts:**
  - **Memory-mapped I/O:** Direct access to keyboard input and display output.
  - **Timer Interrupts:** Ensure responsive, time-based movement.
  - **Linear Congruential Generator:** Implements pseudo-random number generation for apple placement.
- **Optimized Game Logic:** Designed for performance and low-level control.


## 🚀 Getting Started
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/snake-riscv.git
2. **Set Up the RISC-V Environment:**
    - Install the RISC-V toolchain for assembly compilation.
    - Use a RISC-V simulator/emulator for execution (e.g., Spike or QEMU).
3. **Build and Run the Game:**
    - Assemble the game:
        ```bash
        riscv64-unknown-elf-as -o snake.o snake.s
        ```
    - Link the object file:
        ```bash
        riscv64-unknown-elf-ld -o snake snake.o
        ```
    - Execute the game in a simulator:
        ```bash
        spike snake
        ```

## 🎯 How to Play
- Use keyboard controls for snake movement (up, down, left, right).
- Collect apples to grow the snake and increase your score.
- Avoid collisions with the snake's own body or the edges of the display.

## 📂 Project Structure
- `snake.s`: Main assembly source file for the game.
- `README.md`: Documentation for the project (this file).
- Other files as needed for display configurations or helper utilities.

## 💡 Future Enhancements
- Add levels or difficulty scaling.
- Implement a high-score feature using non-volatile memory.
- Optimize further for specific RISC-V implementations.

## 🤝 Contributing
Contributions are welcome! Feel free to fork the repository, create a branch, and submit a pull request.

## 📜 License
This project is licensed under the [Apache 2.0 License](LICENSE).


<!-- 
## Steps to run 🚀
   - Open displayDemo.s inside of rars
   - Assemble the program
   - Open Tools > Keyboard and Display MMIO Simulator
   - Click the "Connect to Program" button in the Keyboard and Display MMIO Simulator
   - Run the program -->