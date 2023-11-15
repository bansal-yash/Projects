LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY vga_tb IS
    --  Port ( );

END vga_tb;

ARCHITECTURE Behavioral OF vga_tb IS

    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL hsync : STD_LOGIC := '0';
    SIGNAL vsync : STD_LOGIC := '0';
    SIGNAL r : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL g : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');

    COMPONENT dist_mem_gen_0
        PORT (
            a : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
    END COMPONENT;

    COMPONENT dist_mem_gen_1
        PORT (
            a : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            d : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            clk : IN STD_LOGIC;
            we : IN STD_LOGIC;
            spo : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
    END COMPONENT;

    SIGNAL clk25 : STD_LOGIC := '0';
    SIGNAL hpos : INTEGER := 0;
    SIGNAL vpos : INTEGER := 0;
    SIGNAL videoon : STD_LOGIC := '0';
    CONSTANT hd : INTEGER := 639;
    CONSTANT hfp : INTEGER := 16;
    CONSTANT hsp : INTEGER := 96;
    CONSTANT hbp : INTEGER := 48;
    CONSTANT vd : INTEGER := 479;
    CONSTANT vfp : INTEGER := 10;
    CONSTANT vsp : INTEGER := 2;
    CONSTANT vbp : INTEGER := 33;
    SIGNAL rom_address : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL data_out_rom : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ram_address : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL data_in : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL wr : STD_LOGIC := '0';
    SIGNAL data_out_ram : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL i : INTEGER := - 1;
    SIGNAL count : INTEGER := 0;
    SIGNAL cycle : INTEGER := 0;
    SIGNAL display_counter : INTEGER := 0;

BEGIN

    clk <= NOT clk AFTER 5 ns;

    clk_div : PROCESS (clk)
        VARIABLE cycle2 : INTEGER := 0;
    BEGIN
        IF (rising_edge(clk)) THEN
            IF (cycle2 = 0) THEN
                clk25 <= '1';
                cycle2 := cycle2 + 1;
            ELSIF (cycle2 = 1) THEN
                cycle2 := cycle2 + 1;
            ELSIF (cycle2 = 2) THEN
                clk25 <= '0';
                cycle2 := cycle2 + 1;
            ELSE
                cycle2 := 0;
            END IF;
        END IF;
    END PROCESS;

    rom : dist_mem_gen_0 PORT MAP(
        a => rom_address,
        spo => data_out_rom);

    ram : dist_mem_gen_1 PORT MAP(
        a => ram_address,
        d => data_in,
        clk => clk25,
        we => wr,
        spo => data_out_ram);

    mux : PROCESS (clk25)
    BEGIN
        IF (rising_edge(clk25)) THEN
            IF (count < 65536) THEN
                IF (i >= 0) THEN
                    ram_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 16));
                END IF;
                wr <= '1';
            ELSE
                ram_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(display_counter, 16));
                wr <= '0';
            END IF;
        END IF;
    END PROCESS;

    image_grad_oper : PROCESS (clk25)
        VARIABLE sum : INTEGER := 0;
        VARIABLE reg1, reg2, reg3 : INTEGER := 0;
    BEGIN
        IF (rising_edge(clk25)) THEN
            IF (i =- 1) THEN
                reg1 := 0;
                reg2 := 0;
                rom_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(0, 16));
                reg3 := TO_INTEGER(unsigned(data_out_rom));
                i <= i + 1;
            ELSIF (i < 65536) THEN
                IF (i MOD 256 > 0 AND i MOD 256 < 255) THEN
                    reg1 := reg2;
                    reg2 := reg3;
                    rom_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(i + 1, 16));
                    reg3 := TO_INTEGER(unsigned(data_out_rom));
                    sum := 2 * reg2 - reg1 - reg3;
                    IF (sum < 0) THEN
                        sum := 0;
                    ELSIF (sum > 255) THEN
                        sum := 255;
                    END IF;
                    data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(sum, 8));
                ELSIF (i MOD 256 = 0) THEN
                    reg1 := 0;
                    reg2 := reg3;
                    rom_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(i + 1, 16));
                    reg3 := TO_INTEGER(unsigned(data_out_rom));
                    sum := 2 * reg2 - reg1 - reg3;
                    IF (sum < 0) THEN
                        sum := 0;
                    ELSIF (sum > 255) THEN
                        sum := 255;
                    END IF;
                    data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(sum, 8));
                ELSIF (i MOD 256 = 255) THEN
                    reg1 := reg2;
                    reg2 := reg3;
                    rom_address <= STD_LOGIC_VECTOR(TO_UNSIGNED(i + 1, 16));
                    reg3 := TO_INTEGER(unsigned(data_out_rom));
                    sum := 2 * reg2 - reg1;
                    IF (sum < 0) THEN
                        sum := 0;
                    ELSIF (sum > 255) THEN
                        sum := 255;
                    END IF;
                    data_in <= STD_LOGIC_VECTOR(TO_UNSIGNED(sum, 8));
                END IF;
                i <= i + 1;
                count <= count + 1;
            END IF;
        END IF;
    END PROCESS;

    horizontal_position_counter : PROCESS (clk25, rst)
    BEGIN
        IF (rst = '1') THEN
            hpos <= 0;
        ELSIF (clk25'event AND clk25 = '1') THEN
            IF (hpos = hd + hfp + hsp + hbp) THEN
                hpos <= 0;
            ELSE
                hpos <= hpos + 1;
            END IF;
        END IF;
    END PROCESS;

    vertical_position_counter : PROCESS (clk25, rst, hpos)
    BEGIN
        IF (rst = '1') THEN
            vpos <= 0;
        ELSIF (clk25'event AND clk25 = '1') THEN
            IF (hpos = hd + hfp + hsp + hbp) THEN
                IF (vpos = vd + vfp + vsp + vbp) THEN
                    vpos <= 0;
                ELSE
                    vpos <= vpos + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    horizontal_synchronisation : PROCESS (clk25, rst, hpos)
    BEGIN
        IF (rst = '1') THEN
            hsync <= '0';
        ELSIF (clk25'event AND clk25 = '1') THEN
            IF (hpos <= (hd + hfp) OR hpos > (hd + hfp + hsp)) THEN
                hsync <= '1';
            ELSE
                hsync <= '0';
            END IF;
        END IF;
    END PROCESS;

    vertical_synchronisation : PROCESS (clk25, rst, vpos)
    BEGIN
        IF (rst = '1') THEN
            vsync <= '0';
        ELSIF (clk25'event AND clk25 = '1') THEN
            IF (vpos <= (vd + vfp) OR vpos > (vd + vfp + vsp)) THEN
                vsync <= '1';
            ELSE
                vsync <= '0';
            END IF;
        END IF;
    END PROCESS;

    video_on : PROCESS (clk25, rst, hpos, vpos)
    BEGIN
        IF (rst = '1') THEN
            videoon <= '0';
        ELSIF (clk25'event AND clk25 = '1') THEN
            IF (hpos <= hd AND vpos <= vd) THEN
                videoon <= '1';
            ELSE
                videoon <= '0';
            END IF;
        END IF;
    END PROCESS;

    draw : PROCESS (clk25, RST, hPos, vPos, videoOn)
    BEGIN
        IF (count = 65536) THEN
            IF (rst = '1') THEN
                R <= "0000";
                G <= "0000";
                B <= "0000";

            ELSIF (clk25'event AND clk25 = '1') THEN
                IF (videoon = '1') THEN

                    IF ((hpos >= 10 AND hpos <= 265) AND (vpos >= 10 AND vpos <= 265)) THEN
                        r(3) <= data_out_ram(7);
                        g(3) <= data_out_ram(7);
                        b(3) <= data_out_ram(7);
                        r(2) <= data_out_ram(6);
                        g(2) <= data_out_ram(6);
                        b(2) <= data_out_ram(6);
                        r(1) <= data_out_ram(5);
                        g(1) <= data_out_ram(5);
                        b(1) <= data_out_ram(5);
                        r(0) <= data_out_ram(4);
                        g(0) <= data_out_ram(4);
                        b(0) <= data_out_ram(4);
                        IF (hpos = 265 AND vpos = 265) THEN
                            display_counter <= 0;
                        ELSE
                            display_counter <= display_counter + 1;
                        END IF;
                    ELSE
                        R <= "0000";
                        G <= "0000";
                        B <= "0000";
                    END IF;
                ELSE
                    R <= "0000";
                    G <= "0000";
                    B <= "0000";
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
END Behavioral;