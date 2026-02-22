library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity CAD is
	Port(
		CLOCK_24 	: in std_logic;
		RESET_N	: in std_logic;
		VGA_B		: out std_logic_vector(1 downto 0);
		VGA_G		: out std_logic_vector(1 downto 0);
		VGA_HS	: out std_logic;
		VGA_R		: out std_logic_vector(1 downto 0);
		VGA_VS	: out std_logic;
		Key : in std_logic_vector(3 downto 0);
		SW : in std_logic_vector(7 downto 0);
		Leds : out std_logic_vector(7 downto 0);
		outseg         : out bit_vector(3 downto 0);
		sevensegments  : out bit_vector(7 downto 0)
	);
end CAD;
 
architecture CAD of CAD is

Component VGA_controller
	port ( CLK_24MHz		: in std_logic;
         VS					: out std_logic;
			HS					: out std_logic;
			RED				: out std_logic_vector(1 downto 0);
			GREEN				: out std_logic_vector(1 downto 0);
			BLUE				: out std_logic_vector(1 downto 0);
			RESET				: in std_logic;
			ColorIN			: in std_logic_vector(5 downto 0);
			ScanlineX		: out std_logic_vector(10 downto 0);
			ScanlineY		: out std_logic_vector(10 downto 0)
  );
end component;

  signal ScanlineX,ScanlineY	: std_logic_vector(10 downto 0);
  signal ColorTable	: std_logic_vector(5 downto 0);
  
  signal seg0, seg1, seg2, seg3 : bit_vector(7 downto 0):=x"c0";
  signal seg_selectors : BIT_VECTOR(3 downto 0) := "1110" ;
  signal output: bit_vector(7 downto 0):=x"c0";
  signal input :Integer range 0 to 100 :=0;
  signal timer_game : Integer range 0 to 100 :=0;
  signal end_game : bit :='0';
  signal score : integer := 0;
  signal lose: bit;
  signal leds_signal : std_logic_vector(7 downto 0) := "10101010";

  constant PATH_W : integer := 6;
  constant C_BG   : std_logic_vector(5 downto 0) := "000000";
  constant C_PATH : std_logic_vector(5 downto 0) := "001111";
  constant C_FRAME: std_logic_vector(5 downto 0) := "111111";

  constant NUM_COLORS : integer := 4;
  constant MAX_BALLS  : integer := 10;
  constant USED_LEN_CONST : integer := 1410; 
  constant BALL_R     : integer := 12;
  constant SPEED_IDX  : integer := 1;
  constant TICK_DIV   : integer := 400000;

  subtype pos_coord is integer range 0 to USED_LEN_CONST-1;
  type pos_arr is array(0 to MAX_BALLS-1) of pos_coord;
  type col_arr is array(0 to MAX_BALLS-1) of std_logic_vector(1 downto 0);

  signal ball_pos   : pos_arr := (others => 0);
  signal ball_col   : col_arr := (others => (others => '0'));
  signal ball_count : integer range 0 to MAX_BALLS := 0;
  signal game_tick  : std_logic := '0';

  constant SH_X0 : integer := 320;
  constant SH_Y0 : integer := 440;
  signal dir_idx : integer range 0 to 6 := 3;
  signal sh_active : std_logic := '0';
  signal sh_x : integer := 0;
  signal sh_y : integer := 0;
  signal sh_col_ready : std_logic_vector(1 downto 0) := "00";
  signal sh_col_shot  : std_logic_vector(1 downto 0) := "00";
  signal sh_col_next  : std_logic_vector(1 downto 0) := "01";

  signal hit_pending : std_logic := '0';
  signal hit_pidx    : integer range 0 to MAX_BALLS-1 := 0;
  signal hit_consume : std_logic := '0';
  
  subtype x_coord is integer range 0 to 639;
  subtype y_coord is integer range 0 to 479;

  type x_arr is array(0 to MAX_BALLS-1) of x_coord;
  type y_arr is array(0 to MAX_BALLS-1) of y_coord;

  signal ball_x : x_arr := (others => 0);
  signal ball_y : y_arr := (others => 0);

  function col2rgb(c : std_logic_vector(1 downto 0)) return std_logic_vector is
  begin
    case c is
      when "00" => return "110000";
      when "01" => return "001100";
      when "10" => return "000011";
      when others => return "111100";
    end case;
  end function;

  function path_x(idx : integer) return integer is
  begin
    if idx < 430 then return 90 + idx;
    elsif idx < 510 then return 520;
    elsif idx < 890 then return 520 - (idx-510);
    elsif idx < 990 then return 140;
    else return 140 + (idx-990);
    end if;
  end function;

  function path_y(idx : integer) return integer is
  begin
    if idx < 430 then return 120;
    elsif idx < 510 then return 120 + (idx-430);
    elsif idx < 890 then return 200;
    elsif idx < 990 then return 200 + (idx-890);
    else return 300;
    end if;
  end function;

  function dir_vx(idx : integer) return integer is
  begin
    case idx is
      when 0 => return -6; when 1 => return -4; when 2 => return -2;
      when 3 => return  0; when 4 => return  2; when 5 => return  4;
      when others => return 6;
    end case;
  end function;

  function dir_vy(idx : integer) return integer is
  begin
    case idx is
      when 0 => return -8; when 1 => return -9; when 2 | 3 | 4 => return -10;
      when 5 => return -9; when others => return -8;
    end case;
  end function;
	
  function clamp_pos(v : integer) return pos_coord is
    variable r : integer;
  begin
    r := v;
    if r < 0 then r := 0;
    elsif r > (USED_LEN_CONST - 1) then r := USED_LEN_CONST - 1;
    end if;
    return r;
  end function;

begin

  game_tick_proc: process(CLOCK_24, RESET_N)
    variable cnt : integer range 0 to TICK_DIV-1 := 0;
  begin
    if RESET_N = '0' then cnt := 0; game_tick <= '0';
    elsif rising_edge(CLOCK_24) then
      if cnt = TICK_DIV-1 then cnt := 0; game_tick <= '1';
      else cnt := cnt + 1; game_tick <= '0'; end if;
    end if;
  end process;

  chain_proc: process(CLOCK_24, RESET_N)
    variable i : integer;
    variable next_pos : integer;
    variable seed : std_logic_vector(1 downto 0);
    variable hp : integer range 0 to MAX_BALLS-1;
    variable ins_pos : pos_coord;
  begin
    if RESET_N = '0' then
      ball_count <= 8;
      score <= 0;
      lose  <= '0';
      hit_consume <= '0';

      for i in 0 to MAX_BALLS-1 loop
        ball_pos(i) <= 0;
        ball_col(i) <= "00";
        ball_x(i)   <= 0;
        ball_y(i)   <= 0;
      end loop;

      for i in 0 to 7 loop
        ball_pos(i) <= (i * 30) mod USED_LEN_CONST;
        ball_x(i)   <= path_x((i * 30) mod USED_LEN_CONST);
        ball_y(i)   <= path_y((i * 30) mod USED_LEN_CONST);
        seed := std_logic_vector(conv_unsigned(i mod NUM_COLORS, 2));
        ball_col(i) <= seed;
      end loop;

    elsif rising_edge(CLOCK_24) then
      if (game_tick = '1') and (end_game = '0') then
        hit_consume <= '0';

        -- COLLISION LOGIC: Simple 2-case rule
        if hit_pending = '1' then
          hp := hit_pidx;

          -- CASE 1: Same color -> DELETE both (hit ball gets removed)
          if ball_col(hp) = sh_col_shot then
            -- Delete the hit ball (shift left to fill gap)
            for i in 0 to MAX_BALLS-2 loop
              if (i >= hp) and (i < ball_count-1) then
                ball_pos(i) <= ball_pos(i+1);
                ball_col(i) <= ball_col(i+1);
                ball_x(i)   <= ball_x(i+1);
                ball_y(i)   <= ball_y(i+1);
              end if;
            end loop;

            if ball_count > 0 then
              ball_count <= ball_count - 1;
            end if;

            score <= score + 1;

          -- CASE 2: Different color -> INSERT shot ball
          else
            if ball_count < MAX_BALLS then
              -- Shift balls after hit position to make room
              for i in MAX_BALLS-1 downto 1 loop
                if (i > hp) and (i <= ball_count) then
                  ball_pos(i) <= ball_pos(i-1);
                  ball_col(i) <= ball_col(i-1);
                  ball_x(i)   <= ball_x(i-1);
                  ball_y(i)   <= ball_y(i-1);
                end if;
              end loop;

              -- Insert shot ball just before hit position
              ins_pos := clamp_pos(ball_pos(hp) - 1);
              ball_pos(hp) <= ins_pos;
              ball_col(hp) <= sh_col_shot;
              ball_x(hp)   <= path_x(ins_pos);
              ball_y(hp)   <= path_y(ins_pos);

              ball_count <= ball_count + 1;
            end if;
          end if;

          hit_consume <= '1';
        end if;

        -- MOVEMENT: Only move if no hit this tick (freeze on collision)
        if hit_pending = '0' then
          if ball_pos(0) >= (USED_LEN_CONST - 1) then
            lose <= '1';
          else
            for i in 0 to MAX_BALLS-1 loop
              if i < ball_count then
                next_pos := ball_pos(i) + SPEED_IDX;
                if next_pos >= USED_LEN_CONST then
                  next_pos := USED_LEN_CONST - 1;
                end if;

                ball_pos(i) <= next_pos;
                ball_x(i)   <= path_x(next_pos);
                ball_y(i)   <= path_y(next_pos);
              end if;
            end loop;

            if ball_pos(0) >= (USED_LEN_CONST - 1 - SPEED_IDX) then
              lose <= '1';
            end if;
          end if;
        end if;

      end if;
    end if;
  end process;

  shooter_proc: process(CLOCK_24, RESET_N)
    variable left_pressed, right_pressed, fire_pressed : std_logic := '1';
  begin
    if RESET_N = '0' then
      dir_idx <= 3; sh_active <= '0'; sh_x <= SH_X0; sh_y <= SH_Y0;
      left_pressed := '1'; right_pressed := '1'; fire_pressed := '1';
    elsif rising_edge(CLOCK_24) then
      if game_tick = '1' and end_game = '0' then
        if (Key(3) = '0') and (left_pressed = '1') then
          if dir_idx > 0 then dir_idx <= dir_idx - 1; end if;
          left_pressed := '0';
        elsif Key(3) = '1' then left_pressed := '1'; end if;

        if (Key(2) = '0') and (right_pressed = '1') then
          if dir_idx < 6 then dir_idx <= dir_idx + 1; end if;
          right_pressed := '0';
        elsif Key(2) = '1' then right_pressed := '1'; end if;

        if (Key(1) = '0') and (fire_pressed = '1') then
          if sh_active = '0' then
            sh_active <= '1'; sh_x <= SH_X0; sh_y <= SH_Y0;
            sh_col_shot <= sh_col_ready; sh_col_ready <= sh_col_next;
            if sh_col_next = "11" then sh_col_next <= "00"; else sh_col_next <= sh_col_next + 1; end if;
          end if;
          fire_pressed := '0';
        elsif Key(1) = '1' then fire_pressed := '1'; end if;

        if sh_active = '1' then
          sh_x <= sh_x + dir_vx(dir_idx);
          sh_y <= sh_y + dir_vy(dir_idx);
          if hit_pending = '1' then sh_active <= '0'; end if;
          if (sh_x + dir_vx(dir_idx) < 0) or (sh_x + dir_vx(dir_idx) > 639) or
             (sh_y + dir_vy(dir_idx) < 0) or (sh_y + dir_vy(dir_idx) > 479) then
            sh_active <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  collision_detect: process(CLOCK_24, RESET_N)
    variable i, dx, dy, bx, by : integer;
  begin
    if RESET_N = '0' then hit_pending <= '0'; hit_pidx <= 0;
    elsif rising_edge(CLOCK_24) then
      if game_tick = '1' then
        if hit_consume = '1' then hit_pending <= '0'; end if;
        if (hit_pending = '0') and (sh_active = '1') then
          for i in 0 to MAX_BALLS-1 loop
            if i < ball_count then
              bx := ball_x(i);
              by := ball_y(i);
              dx := sh_x - bx; if dx < 0 then dx := -dx; end if;
              dy := sh_y - by; if dy < 0 then dy := -dy; end if;
              if (dx <= BALL_R) and (dy <= BALL_R) then
                hit_pending <= '1'; hit_pidx <= i; exit;
              end if;
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;

  VGA_Control: vga_controller
    port map(CLK_24MHz => CLOCK_24, VS => VGA_VS, HS => VGA_HS,
      RED => VGA_R, GREEN => VGA_G, BLUE => VGA_B,
      RESET => not RESET_N, ColorIN => ColorTable,
      ScanlineX => ScanlineX, ScanlineY => ScanlineY);

  process(ScanlineX, ScanlineY, ball_x, ball_y, ball_col, ball_count, sh_active, sh_x, sh_y, dir_idx, sh_col_ready, sh_col_shot)
    variable x, y, i, bx, by, dx, dy : integer;
    variable on_path, on_frame : boolean;
    variable pix : std_logic_vector(5 downto 0);
  begin
    x := conv_integer(ScanlineX);
    y := conv_integer(ScanlineY);
    pix := C_BG;

    on_frame := (x = 0) or (x = 639) or (y = 0) or (y = 479);
    if on_frame then pix := C_FRAME; end if;

    on_path := ((y >= 120 and y < 126) and (x >= 90 and x <= 520)) or
               ((x >= 520 and x < 526) and (y >= 120 and y <= 200)) or
               ((y >= 200 and y < 206) and (x >= 140 and x <= 520)) or
               ((x >= 140 and x < 146) and (y >= 200 and y <= 300)) or
               ((y >= 300 and y < 306) and (x >= 140 and x <= 560));
    if on_path then pix := C_PATH; end if;

    for i in 0 to MAX_BALLS-1 loop
      if i < ball_count then
        bx := ball_x(i);
        by := ball_y(i);
        dx := x - bx; if dx < 0 then dx := -dx; end if;
        dy := y - by; if dy < 0 then dy := -dy; end if;
        if (dx <= BALL_R) and (dy <= BALL_R) then
          pix := col2rgb(ball_col(i)); exit;
        end if;
      end if;
    end loop;

    bx := SH_X0 + 6 * dir_vx(dir_idx);
    by := SH_Y0 + 6 * dir_vy(dir_idx);
    dx := x - bx; if dx < 0 then dx := -dx; end if;
    dy := y - by; if dy < 0 then dy := -dy; end if;
    if (dx <= 2) and (dy <= 2) then pix := "111111"; end if;

    dx := x - SH_X0; dy := y - SH_Y0;
    if dx < 0 then dx := -dx; end if;
    if dy < 0 then dy := -dy; end if;
    if (dx <= BALL_R) and (dy <= BALL_R) then pix := "111111"; end if;

    bx := SH_X0 + 2 * dir_vx(dir_idx);
    by := SH_Y0 + 2 * dir_vy(dir_idx);
    dx := x - bx; if dx < 0 then dx := -dx; end if;
    dy := y - by; if dy < 0 then dy := -dy; end if;
    if (dx <= BALL_R) and (dy <= BALL_R) then pix := col2rgb(sh_col_ready); end if;

    if sh_active = '1' then
      dx := x - sh_x; if dx < 0 then dx := -dx; end if;
      dy := y - sh_y; if dy < 0 then dy := -dy; end if;
      if (dx <= BALL_R) and (dy <= BALL_R) then pix := col2rgb(sh_col_shot); end if;
    end if;

    ColorTable <= pix;
  end process;

  process(CLOCK_24) 
    variable counter : integer range 0 to 5000 :=0;
  begin
    if rising_edge(CLOCK_24) then 
      counter := counter +1;
      if (counter = 4999) then 
        counter :=0;
        seg_selectors <= seg_selectors(0) & seg_selectors(3 downto 1);
      end if;
    end if;
  end process;

  process(CLOCK_24,RESET_N) 
    variable flag_key, flag_rst :bit:= '0';
    variable counter : integer range 0 to 24000000 :=0;
  begin
    if RESET_N = '0' then
      flag_key := '0'; flag_rst := '1'; counter := 0; timer_game <= 0;
    elsif rising_edge(CLOCK_24) then 
      if key(0) = '0' and flag_rst = '1' then flag_key := '1'; end if;
      if flag_key = '1' then
        counter := counter +1;
        if counter = 23999999 then 
          counter :=0;
          if end_game = '1' then timer_game <= timer_game; else timer_game <= timer_game+1; end if;
        end if;
      end if;
    end if;
  end process;

  process(timer_game, score, lose)
  begin
    if (score >= 10) or (timer_game >= 99) or (lose = '1') then end_game <= '1'; else end_game <= '0'; end if;
  end process;

  process(RESET_N,CLOCK_24)
    variable flag_rst: bit := '0';
    variable timer_leds : integer range 0 to 12000001 := 0;
  begin
    if RESET_N = '0' then
      flag_rst := '1'; leds <= "00000000"; leds_signal <= "10101010"; timer_leds := 0;
    elsif rising_edge(CLOCK_24) then
      timer_leds := timer_leds + 1;
      if flag_rst = '1' and end_game = '1' then leds <= "11111111";
      elsif flag_rst = '1' and end_game = '0' and timer_leds = 12000000 then
        leds_signal <= leds_signal(0) & leds_signal (7 downto 1);
        leds <= leds_signal; timer_leds := 0;
      end if;
    end if;
  end process;

  outseg <= seg_selectors;

  process(seg_selectors,seg0,seg1,seg2,seg3)
  begin
    case seg_selectors is
      when "1110" => sevenSegments <= seg0;
      when "0111" => sevenSegments <= seg3;
      when "1011" => sevenSegments <= seg2;
      when "1101" => sevenSegments <= seg1;
      when others => sevenSegments <= x"c0";
    end case;
  end process;

  process(RESET_N,CLOCK_24)
    variable flag_key :bit:= '0';
  begin
    if RESET_N = '0' then
      seg3 <= x"F8"; seg2 <= x"A4"; seg1 <= x"B0"; seg0 <= x"C0"; flag_key := '0';
    elsif rising_edge(CLOCK_24) then 
      if key(0) = '0' then flag_key := '1'; end if;
      if flag_key = '1' and end_game = '0' then
        case score is
          when 0 => seg3 <= x"c0"; seg2 <= x"c0";
          when 1 => seg3 <= x"F9"; seg2 <= x"c0";
          when 2 => seg3 <= x"A4"; seg2 <= x"c0";
          when 3 => seg3 <= x"B0"; seg2 <= x"c0";
          when 4 => seg3 <= x"99"; seg2 <= x"c0";
          when 5 => seg3 <= x"92"; seg2 <= x"c0";
          when 6 => seg3 <= x"82"; seg2 <= x"c0";
          when 7 => seg3 <= x"F8"; seg2 <= x"c0";
          when 8 => seg3 <= x"80"; seg2 <= x"c0";
          when 9 => seg3 <= x"98"; seg2 <= x"c0";
          when 10 => seg3 <= x"c0"; seg2 <= x"F9";
          when others => seg3 <= x"c0"; seg2 <= x"c0";
        end case;
        if timer_game >= 90 then input <= timer_game - 90; seg1 <= output; seg0 <= x"98";
        elsif timer_game >= 80 then input <= timer_game - 80; seg1 <= output; seg0 <= x"80";
        elsif timer_game >= 70 then input <= timer_game - 70; seg1 <= output; seg0 <= x"F8";
        elsif timer_game >= 60 then input <= timer_game - 60; seg1 <= output; seg0 <= x"82";
        elsif timer_game >= 50 then input <= timer_game - 50; seg1 <= output; seg0 <= x"92";
        elsif timer_game >= 40 then input <= timer_game - 40; seg1 <= output; seg0 <= x"99";
        elsif timer_game >= 30 then input <= timer_game - 30; seg1 <= output; seg0 <= x"B0";
        elsif timer_game >= 20 then input <= timer_game - 20; seg1 <= output; seg0 <= x"A4";
        elsif timer_game >= 10 then input <= timer_game - 10; seg1 <= output; seg0 <= x"F9";
        else input <= timer_game; seg1 <= output; seg0 <= x"C0";
        end if; 
      end if;
      if lose='1' or timer_game=99 then
        seg0 <= x"c7"; seg1 <= x"c0"; seg2 <= x"92"; seg3 <= x"86";  
      end if;
      if score>=10 then
        seg0 <= x"92"; seg1 <= x"c1"; seg2 <= x"c6"; seg3 <= x"c6";
      end if;
    end if;
  end process;

  process (input)
  begin
    case input is
      when 0 => output <= x"c0";
      when 1 => output <= x"F9";
      when 2 => output <= x"A4";
      when 3 => output <= x"B0";
      when 4 => output <= x"99";
      when 5 => output <= x"92";
      when 6 => output <= x"82";
      when 7 => output <= x"F8";
      when 8 => output <= x"80";
      when others => output <= x"98";
    end case;
  end process;

end CAD;
