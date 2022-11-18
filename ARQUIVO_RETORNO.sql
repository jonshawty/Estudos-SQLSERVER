create procedure SP_LERARQUIVORETORNO @pathFile varchar(255)
as
begin
	create table #temp(linha varchar(105))
	declare @cmd varchar(255) = 'BULK INSERT #temp FROM ''' + @pathFile + ''''

	execute(@cmd)
	delete from #temp where SUBSTRING(linha,1,1) <> '1'

	declare @linha varchar(255)
	declare @nossoNumero varchar(6)
	declare @dtVencimento date
	declare @dtPagamento date
	declare @valorPago numeric(18,2)
	declare @diasAtraso numeric(18,2)
	declare @valorMulta numeric(18,2) 
	declare @diasMulta NUMERIC(18,2)
	declare @aux numeric(18,4)
	declare @clienteId varchar(10)
	declare @faturaId varchar(10)
	declare @desconto numeric(18,2)
	declare @vlTitulo numeric(18,2)
	declare @vltotal numeric (18,2)

	while exists(select * from #temp)
	begin
			
		set @linha = (select top 1 * from #temp)
		set @nossoNumero = SUBSTRING(@linha,10,6)
		set @dtVencimento = CONVERT(date,SUBSTRING(@linha,16,8),103)
		set @dtPagamento = CONVERT(date,SUBSTRING(@linha,78,8),103)
		set @valorPago = SUBSTRING(SUBSTRING(@linha,40,13), 0,12) + '.' + SUBSTRING(SUBSTRING(@linha,40,13),12,2)
		set @diasAtraso = DATEDIFF(day, @dtvencimento, @dtPagamento)
		set @desconto = SUBSTRING(SUBSTRING(@linha,60,13), 0,12) + '.' + SUBSTRING(SUBSTRING(@linha,60,13),12,2)
		set @vlTitulo = SUBSTRING(SUBSTRING(@linha,24,13), 0,12) + '.' + SUBSTRING(SUBSTRING(@linha,24,13),12,2)

		select @nossoNumero,@dtVencimento,@dtPagamento,@valorPago, @vlTitulo, @diasAtraso

			if @diasAtraso > 0
			begin
				set @vltotal = @vlTitulo - @desconto 
				set @valorMulta= @vltotal * 0.02 
				set @aux = @diasAtraso * 0.004
				set @diasMulta = @vltotal * @aux
				set @valorMulta = @valorMulta + @diasMulta	
				set @clienteId = ( select F.CLIENTEID FROM FATURA F where f.NOSSO_NUMERO = @nossoNumero)
				set @faturaID = ( select F.ID FROM FATURA F where f.NOSSO_NUMERO = @nossoNumero)
				insert into COBRANCAFUTURA (CLIENTEID, FATURAID, VALOR,	DESCRICAO) values (@clienteId, @faturaId, @valorMulta, 'MULTA+JUROS - PG ATRASADO')
			end
	
	
			if @valorPago < @vlTitulo - @desconto 
			begin
				declare @vlRestante numeric(18,2)
				set @vlRestante = @vlTitulo - @valorPago
				set @vltotal = @vlRestante - @desconto
				set @valorMulta = @vltotal * 30 * 0.004
				set @clienteId = ( select F.CLIENTEID FROM FATURA F where f.NOSSO_NUMERO = @nossoNumero)
				set @faturaID = ( select F.ID FROM FATURA F where f.NOSSO_NUMERO = @nossoNumero)
				insert into COBRANCAFUTURA (CLIENTEID, FATURAID, VALOR, DESCRICAO) values (@clienteId, @faturaId, @valorMulta , 'JUROS – PG MENOR')
				insert into COBRANCAFUTURA (CLIENTEID, FATURAID, VALOR, DESCRICAO) values (@clienteId, @faturaId, @vlRestante , 'RESTANTE – PG MENOR')
			end

			if @valorPago > @vlTitulo - @desconto
			begin
				declare @vlDescontoFuturo numeric(18,2)
				set @vltotal = @vlTitulo - @valorPago
				set @vlDescontoFuturo = @vltotal - @desconto
				set @clienteId = ( select F.CLIENTEID FROM FATURA F where f.NOSSO_NUMERO = @nossoNumero)
				set @faturaID = ( select F.ID FROM FATURA F where f.NOSSO_NUMERO = @nossoNumero)
				insert into COBRANCAFUTURA (CLIENTEID, FATURAID, VALOR, DESCRICAO) values (@clienteId, @faturaId, @vlDescontoFuturo , 'DESCONTO – PG MAIOR')
			end

		update fatura set data_pagamento = @dtPagamento
		where nosso_numero = @nossoNumero	
		update fatura set VALOR_PAGO = @valorPago
		where nosso_numero = @nossoNumero	
	    update fatura set DESCONTO = @desconto
		where nosso_numero = @nossoNumero

		delete from #temp where linha = @linha

	end
	
	drop table #temp
end

exec SP_LERARQUIVORETORNO 'C:\Users\wemer\OneDrive\Área de Trabalho\TP1\file1.txt'
exec SP_LERARQUIVORETORNO 'C:\Users\wemer\OneDrive\Área de Trabalho\TP1\file2.txt'
exec SP_LERARQUIVORETORNO 'C:\Users\wemer\OneDrive\Área de Trabalho\TP1\file3.txt'

select * from FATURA
select * from COBRANCAFUTURA
select * from CLIENTE

