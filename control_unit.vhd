library IEEE;
use IEEE.std_logic_1164.all
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity control_unit is
	port(
		clk			: in std_logic;
		rst			: in std_logic;
		CCR_Result	: in std_logic_vector(3 downto 0);
		IR			: in std_logic_vector(7 downto 0);
		-- Outputs:
		IR_Load		: out std_logic;	-- Komut register'i y�kleme ve kontol etme
		MAR_Load	: out std_logic;
		PC_Load		: out std_logic;
		PC_Inc		: out std_logic;
		A_Load		: out std_logic;
		B_Load		: out std_logic;
		ALU_Sel		: out std_logic;
		CCR_Load	: out std_logic;
		BUS1_Sel	: out std_logic_vector(1 downto 0);
		BUS2_Sel	: out std_logic_vector(1 downto 0);
		write_en	: out std_logic	
	);
end control_unit;

architecture arch of control_unit is

type state_type is	(
						S_FETCH_0, S_FETCH_1, S_FETCH_2, S_DECODE_3,
						S_LDA_IMM_4, S_LDA_IMM_5, S_LDA_IMM_6,
						S_LDA_DIR_4, S_LDA_DIR_5, S_LDA_DIR_6, S_LDA_DIR_7, S_LDA_DIR_8,
						S_LDB_IMM_4, S_LDB_IMM_5, S_LDB_IMM_6,
						S_LDB_DIR_4, S_LDB_DIR_5, S_LDB_DIR_6, S_LDB_DIR_7, S_LDB_DIR_8,
						S_STA_DIR_4, S_STA_DIR_5, S_STA_DIR_6, S_STA_DIR_7,
						S_ADD_AB_4,
						S_BRA_4, S_BRA_5, S_BRA_6,
						S_BEQ_4, S_BEQ_5, S_BEQ_6, S_BEQ_7,
					);
					
signal current_state, next_state	: state_type;

-- T�m Komutlar:
-- Kaydetme ve Y�kleme
constant YUKLE_A_SBT	: std_logic_vector(7 downto 0) := x"86";
constant YUKLE_A		: std_logic_vector(7 downto 0) := x"87";
constant YUKLE_B_SBT	: std_logic_vector(7 downto 0) := x"88";
constant YUKLE_B		: std_logic_vector(7 downto 0) := x"89";
constant KAYDET_A		: std_logic_vector(7 downto 0) := x"96";
constant KAYDET_B		: std_logic_vector(7 downto 0) := x"97";
-- ALU
constant TOPLA_AB		: std_logic_vector(7 downto 0) := x"42";
constant CIKAR_AB		: std_logic_vector(7 downto 0) := x"43";
constant AND_AB			: std_logic_vector(7 downto 0) := x"44";
constant OR_AB 			: std_logic_vector(7 downto 0) := x"45";
constant ARTTIR_A		: std_logic_vector(7 downto 0) := x"46";
constant ARTTIR_B		: std_logic_vector(7 downto 0) := x"47";
constant AZALT_A		: std_logic_vector(7 downto 0) := x"48";
constant AZALT_B		: std_logic_vector(7 downto 0) := x"49";
-- Atlama Ko�ullu/Ko�ulsuz
constant ATLA					: std_logic_vector(7 downto 0) := x"20";
constant ATLA_NEGATIFSE			: std_logic_vector(7 downto 0) := x"21";
constant ATLA_POZITIFSE			: std_logic_vector(7 downto 0) := x"22";
constant ATLA_ESITSE_SIFIR		: std_logic_vector(7 downto 0) := x"23";
constant ATLA_DEGILSE_SIFIR		: std_logic_vector(7 downto 0) := x"24";
constant ATLA_OVERFLOW_VARSA	: std_logic_vector(7 downto 0) := x"25";
constant ATLA_OVERFLOW_YOKSA	: std_logic_vector(7 downto 0) := x"26";
constant ATLE_ELDE_VARSA		: std_logic_vector(7 downto 0) := x"27";
constant ATLA_ELDE_YOKSA		: std_logic_vector(7 downto 0) := x"28";

begin

-- Current State Logic
	process(clk, rst)
	begin
		if(rst = '1') then
			current_state <= S_FETCH_0;
		elsif(rising_edge(clk)) then	
			current_state <= next_state;
		end if
	end process;
	
-- Next State Logic
	process(current_state, IR, CCR_Result)
	begin
		case
			when S_FETCH_0	 => 
				next_state <= S_FETCH_1;
				
			when S_FETCH_1 	 => 
				next_state <= S_FETCH_2;
				
			when S_FETCH_2	 => 
				next_state <= S_DECODE_3;
				
			when S_DECODE_3	 => 
				if(IR = YUKLE_A_SBT) then
					next_state <= S_LDA_IMM_4;
				elsif(IR = YUKLE_A) then
					next_state <= S_LDA_DIR_4;
				elsif(IR = YUKLE_B_SBT) then
					next_state <= S_LDB_IMM_4;
				elsif(IR = YUKLE_B) then
					next_state <= S_LDB_DIR_4;
				elsif(IR = KAYDET_A) then
					next_state <= S_STA_DIR_4;
				elsif(IR = TOPLA_AB) then
					next_state <= S_ADD_AB_4;
				elsif(IR = ATLA) then
					next_state <= S_BRA_4;
				elsif(IR = ATLA_ESITSE_SIFIR) then
					if(CCR_Result(2) = '1')		-- NZVC, Zero bilgisi 2. bit oldugu icin
						next_state <= S_BEQ_4;
					else	-- Z = '0'
						next_state <= S_BEQ_7;
					end if;
				else
					next_state <= S_FETCH_0;				
				end if;
				
-------------------------------------------------------				
				
			when S_LDA_IMM_4 => 
				next_state <= S_LDA_IMM_5;
				
			when S_LDA_IMM_5 => 
				next_state <= S_LDA_IMM_6;
				
			when S_LDA_IMM_6 => 
				next_state <= S_FETCH_0;
			----------------------------
			when S_LDA_DIR_4 => 
				next_state <= S_LDA_DIR_5;
				
			when S_LDA_DIR_5 => 
				next_state <= S_LDA_DIR_6;
				
			when S_LDA_DIR_6 => 
				next_state <= S_LDA_DIR_7;
				
			when S_LDA_DIR_7 => 
				next_state <= S_LDA_DIR_8;
				
			when S_LDA_DIR_8 => 
				next_state <= S_FETCH_0;
			----------------------------
			when S_LDB_IMM_4 => 
				next_state <= S_LDB_IMM_5;
				
			when S_LDB_IMM_5 => 
				next_state <= S_LDB_IMM_6;
				
			when S_LDB_IMM_6 => 
				next_state <= S_FETCH_0;
			----------------------------
			when S_LDB_DIR_4 => 
				next_state <= S_LDB_DIR_5;
				
			when S_LDB_DIR_5 => 
				next_state <= S_LDB_DIR_6;
				
			when S_LDB_DIR_6 => 
				next_state <= S_LDB_DIR_7;
				
			when S_LDB_DIR_7 => 
				next_state <= S_LDB_DIR_8;
				
			when S_LDB_DIR_8 => 
				next_state <= S_FETCH_0;
			----------------------------	
			when S_STA_DIR_4 => 
				next_state <= S_STA_DIR_5;
				
			when S_STA_DIR_5 => 
				next_state <= S_STA_DIR_6;
				
			when S_STA_DIR_6 => 
				next_state <= S_STA_DIR_7;
				
			when S_STA_DIR_7 => 
				next_state <= S_FETCH_0;
			----------------------------	
			when S_ADD_AB_4  => 
				next_state <= S_FETCH_0;
			----------------------------
			when S_BRA_4     => 
				next_state <= S_BRA_5;
				
			when S_BRA_5     => 
				next_state <= S_BRA_6;
				
			when S_BRA_6     => 
				next_state <= S_FETCH_0;
			----------------------------
			when S_BEQ_4     =>
				next_state <= S_BEQ_5;
				
			when S_BEQ_5     => 
				next_state <= S_BEQ_6;
				
			when S_BEQ_6     => 
				next_state <= S_FETCH_0;
				
			when S_BEQ_7     =>		-- Z = '0' durumu, komut bypass(isleme alinmadi)
				next_state <= S_FETCH_0;
			----------------------------
			when others      =>
				next_state <= S_FETCH_0;
		end case;
	end process;

-- Output Logic 
	process(current_state)
	begin
	
		IR_Load   <= '0';
		MAR_Load  <= '0';
		PC_Load   <= '0';
		A_Load    <= '0';
		B_Load    <= '0';
		ALU_Sel   <= (others => '0');
		CCR_Load  <= '0';
		BUS1_Sel  <= (others => '0');
		BUS2_Sel  <= (others => '0');
		write_en  <= '0';
		
		case current_state is
		when S_FETCH_0	 => 
				BUS1_Sel <= "00";	-- PC
				BUS2_Sel <= "01";	-- BUS1
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi 
				
			when S_FETCH_1 	 => 
				PC_Inc <= '1';		-- Program sayacinin degeri arttiriliyor
				
			when S_FETCH_2	 => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				IR_Load  <= '1';	-- bellekteki data komut register'�na y�kleniyor
				
			when S_DECODE_3	 => 
				-- Next state g�ncellendi, ilgili dallanma saglandi
				
-------------------------------------------------------				
				
			when S_LDA_IMM_4 => 
				BUS1_Sel <= "00";	-- PC
				BUS2_Sel <= "01";	-- BUS1
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi 
				
			when S_LDA_IMM_5 => 
				PC_Inc <= '1';		-- Program sayacinin degeri arttiriliyor
				
			when S_LDA_IMM_6 => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				A_Load   <= '1';	-- A register'ina istenilen data yaziliyor
			----------------------------
			when S_LDA_DIR_4 => 
				BUS1_Sel <= "00";	-- PC
				BUS2_Sel <= "01";	-- BUS1
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi
				
			when S_LDA_DIR_5 => 
				PC_Inc <= '1';		-- Program sayacinin degeri arttiriliyor
				
			when S_LDA_DIR_6 => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi (Data veri belleginden okunuyor)
				
			when S_LDA_DIR_7 => 
				-- BOS (Bellekten data okunmasi bekleniyor)
				
			when S_LDA_DIR_8 => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				A_Load   <= '1';	-- A register'ina data y�kleniyor
			----------------------------
			when S_LDB_IMM_4 => 
				BUS1_Sel <= "00";	-- PC
				BUS2_Sel <= "01";	-- BUS1
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi 
				
			when S_LDB_IMM_5 => 
				PC_Inc <= '1';		-- Program sayacinin degeri arttiriliyor
				
			when S_LDB_IMM_6 => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				B_Load   <= '1';	-- B register'ina istenilen data yaziliyor
			----------------------------
			when S_LDB_DIR_4 => 
				BUS1_Sel <= "00";	-- PC
				BUS2_Sel <= "01";	-- BUS1
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi
				
			when S_LDB_DIR_5 => 
				PC_Inc <= '1';		-- Program sayacinin degeri arttiriliyor
				
			when S_LDB_DIR_6 => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi (Data veri belleginden okunuyor)
				
			when S_LDB_DIR_7 => 
				-- BOS (Bellekten data okunmasi bekleniyor)
				
			when S_LDB_DIR_8 => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				B_Load   <= '1';	-- B register'ina data y�kleniyor
			----------------------------			
			when S_STA_DIR_4 => 
				BUS1_Sel <= "00";	-- PC
				BUS2_Sel <= "01";	-- BUS1
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi
				
			when S_STA_DIR_5 => 
				PC_Inc <= '1';		-- Program sayacinin degeri arttiriliyor
				
			when S_STA_DIR_6 => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi (Data veri belleginden okunuyor)
				
			when S_STA_DIR_7 => 
				BUS1_Sel <= "01";	-- A register'i BUS1 ile bellege g�nderiliyor
				write_en <= '1';	-- Yazdiriliyor
			----------------------------	
			when S_ADD_AB_4  => 
				BUS1_Sel <= "01";	-- A register'i BUS1 ile ALU'ya g�nderiliyor
				BUS2_Sel <= "00";	-- BUS2 ALU result'a veriliyor
				ALU_Sel  <= "000";	-- ALU'daki toplama kodu
				A_Load   <= '1';	-- Sonuc A register'a y�kleniyor (BUS2'daki ALU result A register'a y�kleniyor)
				CCR_Load <= '1';	-- CCR bilgisi CCR register'a y�kleniyor
			----------------------------
			when S_BRA_4     => 
				BUS1_Sel <= "00";	-- PC
				BUS2_Sel <= "01";	-- BUS1
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi
				
			when S_BRA_5     => 
				-- BOS (Bekleme asamasi: adresin iletilmesi ve datanin gelmesi icin) 
				
			when S_BRA_6     => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				PC_Load  <= '1';	-- BUS2'ye gelen veri PC register'ina y�kleniyor 
			----------------------------
			when S_BEQ_4     =>
				BUS1_Sel <= "00";	-- PC
				BUS2_Sel <= "01";	-- BUS1
				MAR_Load <= '1',	-- BUS2'deki program sayaci degeri MAR'a alindi
				
			when S_BEQ_5     => 
				-- BOS (Bekleme asamasi: adresin iletilmesi ve datanin gelmesi icin) 
				
			when S_BEQ_6     => 
				BUS2_Sel <= "10";	-- from memory: bellekten okunan data
				PC_Load  <= '1';	-- BUS2'ye gelen veri PC register'ina y�kleniyor 
				
			when S_BEQ_7     =>		-- Branch'in alinmama durumu
				PC_Inc   <= '1';	-- PC hicbir sey olmamis gibi artiyor 
			----------------------------
			when others      =>
				IR_Load   <= '0';
				MAR_Load  <= '0';
				PC_Load   <= '0';
				A_Load    <= '0';
				B_Load    <= '0';
				ALU_Sel   <= (others => '0');
				CCR_Load  <= '0';
				BUS1_Sel  <= (others => '0');
				BUS2_Sel  <= (others => '0');
				write_en  <= '0';
		end case;
	end process;

end architecture;