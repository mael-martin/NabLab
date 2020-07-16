#include <iostream>
#include "Schema_chap2Functions.h"

float Schema_chap2Functions::nextWaveHeight()
{
	if(data != NULL)
	{
		depth = data[count++];
		if(count != count_max)
		   return depth;
		else
		{
			free(data);
			return depth;
		}
	}
	else
	{
		int ncid, varid, retval, n;
		size_t* len;

		//ouvre le fichier
		if((retval = nc_open(fileName.c_str(), NC_NOWRITE, &ncid)))
			std::cout << retval <<"error nc open"<< std::endl;

		//recupere l'ID de la data nommé "z"
		if((retval = nc_inq_varid(ncid, "z", &varid)))
			std::cout << retval <<"  error nc inq varid z"<< std::endl;

		// recupere le nombre de dimension
		nc_inq_ndims(ncid, &n);
		len = (size_t*)malloc(n * sizeof(size_t));

		//recupere les length des dimensions
		for(int i = 0 ; i < n ; i++)
			nc_inq_dimlen(ncid, i, len+i);

		for(int i = 0 ; i < n ; i++)
			{std::cout << "dim"<<i<< "_len = "<< *(len+i) << std::endl; count_max *= *(len+i);}


		// allouer la bonne taille
		data = (float*)malloc(count_max * sizeof(float));

		// recupere les data
		if((retval = nc_get_var_float(ncid, varid, data)))
			std::cout << "error get var float" << std::endl;

		// liberer la memoire
		nc_close(ncid);
		free(len);

		depth = data[count++];
		return depth;
	}

}
