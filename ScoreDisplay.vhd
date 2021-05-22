library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity ScoreDisplay is
  port (
    score       : in integer range 0 to 99;
    seven_seg_0 : out std_logic_vector(6 downto 0);
    seven_seg_1 : out std_logic_vector(6 downto 0)
  );
end entity ScoreDisplay;

architecture rtl of ScoreDisplay is
  signal digit0 : std_logic_vector(3 downto 0);
  signal digit1 : std_logic_vector(3 downto 0);

  component SevenSegDecoder is
    port (
      input  : in std_logic_vector (3 downto 0);
      output : out std_logic_vector (6 downto 0)
    );
  end component;

  component IntToBCD is
    port (
      number : in integer range 0 to 99;
      digit0 : out std_logic_vector (3 downto 0);
      digit1 : out std_logic_vector (3 downto 0)
    );
  end component;
begin

  int_to_bcd : IntToBCD port map(
    number => score,
    digit0 => digit0,
    digit1 => digit1
  );

  decoder_0 : SevenSegDecoder port map(
    input  => digit0,
    output => seven_seg_0
  );

  decoder_1 : SevenSegDecoder port map(
    input  => digit1,
    output => seven_seg_1
  );
end architecture;