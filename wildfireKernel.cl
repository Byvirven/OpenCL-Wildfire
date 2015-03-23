int west(int position, int width) {
	if (position-1 < 0 or (position-1!=0 and
		(position-1)/width < position/width)) {
		return position-1+width;
	}
	return position-1;
}

int east(int position, int width, int size) {
	if (position+1 >= size or 
		(position+1)/width > position/width) {
		return position+1-width;
	}
	return position+1;
}

int north(int position, int width, int size) {
	if (position-width < 0) {
		return position-width+size;
	}
	return position-width;
}

int south(int position, int width, int size) {
	if (position+width >= size) {
		return (position+width)%size;
	}
	return position+width;
}

int LFG(int seed0, int seed1, int k, int modulo) {
	int x0 = seed0; int x1 = seed1;
	int randNumber = 0;
	for (int i=0;i<k;i++) {
		randNumber = (x0+x1)%modulo;
		x0 = x1;
		x1 = randNumber;
	}
	return randNumber;
}
__kernel void wildfire(__global const uchar *img, 
					__global const int *width, 
					__global const int *size,  
					__global const int *seed, 
					__global uchar *imgtmp) {
	int i = get_global_id(0); // identifiant global
	int position = i*3;
	int k[16] = {10, 17, 55, 71, 159, 31, 63, 127, 521, 607, 1279, 89, 100, 258, 378, 607};
	int randNumber = LFG(	seed[0]+position,
							seed[1]+i,
							k[((seed[0]+i)*abs(seed[1]-position))%16],
							abs(seed[2]-i)+1
						)%width[0];
	switch (img[position]) {
		case 0x00 : //#AEEE00  --> vert --> vivant
			// si aucun arbre ne brûle autours
			// alors 20% de chances de s'embraser
			if (img[west(i, width[0])*3] != 0x39 and
			img[east(i,width[0],size[0])*3] != 0x39 and 
			img[north(i,width[0],size[0])*3] != 0x39 and
			img[south(i,width[0],size[0])*3] != 0x39) {
				if (randNumber%5 != 0) {
					// ne brûle pas
					imgtmp[position] = 0x00;
					imgtmp[position+1] = 0xEE;
					imgtmp[position+2] = 0xAE;
				} else {
					// brûle
					imgtmp[position] = 0x39;
					imgtmp[position+1] = 0x07;
					imgtmp[position+2] = 0xE7;
				}
			// sinon les chances de prendre feu
			// montent sont 100%
			} else {
				// brûle
				imgtmp[position] = 0x39;
				imgtmp[position+1] = 0x07;
				imgtmp[position+2] = 0xE7;
			}
			
			break;
		case 0x39 : //#E70739 --> rouge --> en train de bruler
			// se transforme en charbon ardent
			imgtmp[position] = 0x87;
			imgtmp[position+1] = 0x90;
			imgtmp[position+2] = 0x99;
			break;
		case 0x87 : //#999087 --> gris --> cendre
			// se transforme en terre brulé
			imgtmp[position] = 0x46;
			imgtmp[position+1] = 0x8D;
			imgtmp[position+2] = 0xBD;
			break;
		default: //#BD8D46 --> brun --> terre
			// si terre, alors  33 % de chances de
			// repousser
			if (randNumber%3 != 0) {
				// ne repousse pas
				imgtmp[position] = 0x46;
				imgtmp[position+1] = 0x8D;
				imgtmp[position+2] = 0xBD;
			} else {
				// repousse #AEEE00
				imgtmp[position] = 0x00;
				imgtmp[position+1] = 0xEE;
				imgtmp[position+2] = 0xAE;
			}
	}
}
