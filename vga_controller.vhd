library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA_controller is
  port (    CLK_24MHz		: in std_logic;
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
end VGA_controller;

architecture Behavioral of VGA_controller is
  -- VGA Definitions
  constant HDisplayArea: integer:= 640; -- horizontal display area
  constant HLimit: integer:= 800; -- maximum horizontal amount (limit)
  constant HFrontPorch: integer:= 16; -- h. front porch  16
  constant HBackPorch: integer:= 48;	-- h. back porch   48
  constant HSyncWidth: integer:= 96;	-- h. pulse width   96
  constant VDisplayArea: integer:= 480; -- vertical display area
  constant VLimit: integer:= 525; -- maximum vertical amount (limit)
  constant VFrontPorch: integer:= 10;	-- v. front porch
  constant VBackPorch: integer:= 33;	-- v. back porch
  constant VSyncWidth: integer:= 2;	-- v. pulse width      

  signal HBlank, VBlank, Blank: std_logic := '0';

  signal CurrentHPos: std_logic_vector(10 downto 0) := (others => '0'); -- goes to 1100100000 = 800
  signal CurrentVPos: std_logic_vector(10 downto 0) := (others => '0'); -- goes to 1000001101 = 525

begin

  VGAPosition: process (Clk_24MHz, RESET)
  begin
    if RESET = '1' then
	   CurrentHPos <= (others => '0');
		CurrentVPos <= (others => '0');
    elsif rising_edge(CLK_24MHz) then
	   if CurrentHPos < HLimit-1 then
		  CurrentHPos <= CurrentHPos + 1;
		else
		  if CurrentVPos < VLimit-1 then
		    CurrentVPos <= CurrentVPos + 1;
		  else
		    CurrentVPos <= (others => '0'); -- reset Vertical Position
		  end if;
		  CurrentHPos <= (others => '0'); -- reset Horizontal Position
		end if;
	 end if;
  end process VGAPosition;

		-- Timing definition for HSync, VSync and Blank
		HS <= '0' when CurrentHPos < HSyncWidth else
				 '1';

		VS <= '0' when CurrentVPos < VSyncWidth else
				 '1';
				 
		-- Active video region (use BackPorch, not FrontPorch)
		HBlank <= '0' when (CurrentHPos >= HSyncWidth + HBackPorch) and
							  (CurrentHPos <  HSyncWidth + HBackPorch + HDisplayArea) else
					 '1';

		VBlank <= '0' when (CurrentVPos >= VSyncWidth + VBackPorch) and
							  (CurrentVPos <  VSyncWidth + VBackPorch + VDisplayArea) else
					 '1';

		Blank <= '1' when (HBlank = '1' or VBlank = '1') else '0';

		-- Pixel coordinates inside visible area
		ScanlineX <= (CurrentHPos - (HSyncWidth + HBackPorch)) when Blank = '0' else (others => '0');
		ScanlineY <= (CurrentVPos - (VSyncWidth + VBackPorch)) when Blank = '0' else (others => '0');

		-- Drive VGA colors based on ColorIN
		RED   <= ColorIN(5 downto 4) when (Blank = '0') else "00";
		GREEN <= ColorIN(3 downto 2) when (Blank = '0') else "00";
		BLUE  <= ColorIN(1 downto 0) when (Blank = '0') else "00";


end Behavioral;
