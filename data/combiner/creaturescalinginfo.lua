-------------------------------------------------------------------------------
--	Creature Scaling Info
--
--	This file contains the data that tells the combiner what size a result
-- 	creature should be after it comes out of the combiner.
--	i.e. if it is a size 5 creature it should be this volume within these
--	x,y,z tolerances

-- OBBVol	- the desired volume (in meters) of the oriented bounding box for the combined creature at that size
-- maxXdim	- the maximum the X dimension (left-right) size the creature can get (in meters)
-- maxYdim	- the maximum the Y dimension (ground-heighest point) size the creature can get (in meters)
-- maxZdim	- the maximum the Z dimension (front-back) size the creature can get (in meters)

SizeScaling =
{
	{	-- Size 1 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 2.0,
		maxYdim     = 2.1,
		maxZdim     = 2.1,
	},
	{	-- Size 2 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 2.5,
		maxYdim     = 3.0,
		maxZdim     = 2.6,
	},
	{	-- Size 3 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 3.3,
		maxYdim     = 7.0,
		maxZdim     = 3.3,
	},
	{	-- Size 4 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 5.5,
		maxYdim     = 5.9,
		maxZdim     = 5.5,
	},
	{	-- Size 5 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 8.5,
		maxYdim     = 9.6,
		maxZdim     = 9.1,
	},
	{	-- Size 6 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 13.5,
		maxYdim     = 15.6,
		maxZdim     = 13.7,
	},
	{	-- Size 7 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 21.0,
		maxYdim     = 24.8,
		maxZdim     = 21.6,
	},
	{	-- Size 8 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 33.0,
		maxYdim     = 40.0,
		maxZdim     = 33.8,
	},
	{	-- Size 9 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 52.0,
		maxYdim     = 63.8,
		maxZdim     = 53.1,
	},
	{	-- Size 10 Creature
		FootPrint	= 80000.0,
		OBBVol		= 800.0,
		maxXdim     = 80.0,
		maxYdim     = 96.0,
		maxZdim     = 80.0,
	},
}

