module hamming_encoder
	(
		output reg[16:1] out;
		input[10:0] in; //Sunt necesari 4 biti extra pentru
							//codarea datelor
	)

	reg[3:0] i; //Index, valoarea maxima necesara este 15
	//Se face atribuirea bitilor de date, schimbarea bitilor
	//de paritate 0,1,3,7 facandu-se ulterior;
	out[3] = in[0];
	out[5] = in[1];
	out[6] = in[2];
	out[7] = in[3];
	for(i=1;i<8;i=i+1)
	begin
		out[i+8]=in[i+3];
	end
	//Se face codarea bitilor originali
	out[1] = (out[3]+out[5]+out[7]+out[9]+out[11]+out[13]+out[15])%2;
	//1: se incepe cu pozitia 3 si se verifica din 1 in 1 biti datele
	out[2] = (out[3]+out[6]+out[7]+out[10]+out[11]+out[14]+out[15])%2;
	//2: se incepe cu pozitia 2 si se verifica din 2 in 2 biti datele
	//Se verifica si pozitia 3 deoarece nu s-a inceput verificarea cu prima
	//grupare de 2 biti, [2,3], deoarece bitul 2 este nedefinit
	out[4] = (out[5]+out[6]+out[7]+out[12]+out[13]+out[14]+out[15])%2;
	//4: se incepe cu pozitia 5 si se verifica 3 biti, gruparea de 4 biti
	//verificata este [4,5,6,7], dar bitul 4 este nedefinit
	//Se verifica si urmatoarea grupare de 4 biti
	out[8] = (out[9]+out[10]+out[11]+out[12]+out[13]+out[14]+out[15])%2;
	//8: se incepe cu pozitia 9 si se verifica cei 7 biti ramasi
	//Uzual s-ar verifica gruparea [8,9,10,11,12,13,14,15], dar bitul 8 este nedefinit
	//Bitul 16 nu este luat in considerare, el fiind bit de paritate
	out[16]=0; //Consideram ca este par sirul, iar apoi adaugam valorile
			   //din bitii respectivi in bitul 16 pentru a deduce paritatea sirului 
	for(i=1;i<16;i=i+1)
		out[16] = out[16]+out[i];
endmodule

module hamming_decoder
	(
		output reg[10:0] out, // mesaj corectat
        output[3:0] error_index, // numarul bitului corectat (1-15)
        output error, // 1 daca a fost detectata cel putin o eroare
        output uncorrectable, // 1 daca au fost detectate doua erori
        input[16:1] in
	)
	reg[3:0] i,j,k;
	error=0;
	reg x; //Registru sa verific daca paritatea sirului concide cu cea din b16
	//Recalcularea bitilor de paritate in functie de sirul trimis
	k[0] = (in[3]+in[5]+in[7]+in[9]+in[11]+in[13]+in[15])%2;
	k[1] = (in[3]+in[6]+in[7]+in[10]+in[11]+in[14]+in[15])%2;
	k[2] = (in[5]+in[6]+in[7]+in[12]+in[13]+in[14]+in[15])%2;
	k[3] = (in[9]+in[10]+in[11]+in[12]+in[13]+in[14]+in[15])%2;

	for(i=1;<16;i=i+1)
	begin
		error=error+in[i]; //Folosesc error ca variabila auxiliara pentru verificarea paritatii
	end
	if(error==in[16]) x=1;
		else x=0;

	j=in[1]^k[0]+in[2]^k[1]+in[4]^k[2]+in[8]^k[3]; //Se verifica corectitudinea bitilor de paritate generati de sir
	case(j)
		1: //Daca se gaseste un singur bit eronat atunci este schimbat si se reface sirul
			if(in[1]^k[0]) 
			begin
				error_index = 1;
				in[1]=~in[1];
			end
			if(in[2]^k[1]) 
			begin
				error_index = 2;
				in[2]=~in[2];
			end
			if(in[4]^k[2]) 
			begin
				error_index = 4;
				in[4]=~in[4];
			end
			if(in[8]^k[3])
			begin
				error_index = 8;
				in[8]=~in[8];
			end

			error = 1;
		2: in[{in[8]^k[3],in[4]^k[2],in[2]^k[1],in[1]^k[1]}] = ~in[{in[8]^k[3],in[4]^k[2],in[2]^k[1],in[1]^k[1]}];
			error = 1;
			//Daca 2 biti difera inseamna ca este o greseala in bitul lor comun, deci acesta trebuie inversat
			//in[...] face XOR intre cei 4 biti si genereaza un sir cu 0 pe biti identici si 1 pe biti de paritate diferiti,
			//iar bitul gresit corespunde reprezentarii acestora in baza zece spre ex daca difera bitul 10 atunci o sa avem
			//in[10]=in[1'b1001] deci ar trebui sa difere bitii 8 si 1 din sirul initial
		3: if(x==1) uncorrectable = 1; //Daca paritatea este aceeasi, dar difera 3 biti de paritate inseamna ca au fost modificati
									   //2 biti din sir deci nu mai poate fi corectat;
									   //Daca paritatea este diferita insa inseamna ca trebuie modificat doar bitul comun celor 3
									   //biti de paritate
					error = 1;
			else begin
				in[{in[8]^k[3],in[4]^k[2],in[2]^k[1],in[1]^k[1]}] = ~in[{in[8]^k[3],in[4]^k[2],in[2]^k[1],in[1]^k[1]}];
				//Se foloseste aceeasi idee ca mai sus cu XOR intre bitii de paritate	
			end
		4: uncorrectable = 1; //Daca sunt toti cei 4 biti de paritate diferiti inseamna ca fie unul dintre acestia este eronati,
							  //fie cel putin 2 biti encriptati sunt eronati, codul ne mai putand fi corectati
			error = 1;
	endcase

	out[0] =in[1]+in[2];
	out[1] =in[4]+in[1];
	out[2] =in[4]+in[2];
	out[3] =in[4]+in[2]+in[1];
	out[4] =in[8]+in[1];
	out[5] =in[8]+in[2];
	out[6] =in[8]+in[2]+in[1];
	out[7] =in[8]+in[4];
	out[8] =in[8]+in[4]+in[1];
	out[9] =in[8]+in[4]+in[2];
	out[10]=in[8]+in[4]+in[2]+in[1];

endmodule