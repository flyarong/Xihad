#include "CBaseTickMethod.hpp"
#include <cassert>
#include <cfloat>

namespace xihad { namespace dialogue
{
	CBaseTickMethod::CBaseTickMethod( float standardCycle, float initSpeed ) :
		mStandardCycle(standardCycle)
	{
		assert(mStandardCycle > 0);
		setTickSpeed(initSpeed);
	}

	void CBaseTickMethod::setTickSpeed( float speed )
	{
		if (speed == 0.f)
		{
			mTimer.setCycle(FLT_MAX);
		}
		else
		{
			assert(speed > 0);
			mTimer.setCycle(mStandardCycle / speed);
		}
	}

	float CBaseTickMethod::getTickSpeed() const
	{
		float cycle = mTimer.getCycle();
		return mStandardCycle/cycle;
	}

	void CBaseTickMethod::tick( float delta )
	{
		if (mTimer.satisfy(delta))
		{
			onTick();
		}
	}

}}

